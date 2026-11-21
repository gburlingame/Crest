#!/bin/zsh
set -euo pipefail

# Builds Thundermist, a private build of Crest, signs it with this Mac's Apple
# Development identity, and installs it in /Applications. It never touches an
# installed official Crest. The Chromium engine is the one Crest published for
# this checkout's engine inputs. It builds from a copy of the source with the
# product name applied (Scripts/thundermist-rebrand.py), so this repository keeps
# upstream's text and merges stay clean.
#
# Usage: Scripts/install-thundermist.sh [--provision-only] [--no-install] [--no-open]
#        Scripts/install-thundermist.sh --dmg [--development] [--output <path>.dmg]
#   --no-install leaves the signed app in ~/Library/Caches/Thundermist and does
#   not touch /Applications or a running Thundermist.
#   --dmg signs with the team's Developer ID instead, has Apple notarize the app
#   and a disk image holding it, and leaves the image on the Desktop (or at
#   --output), for any Apple Silicon Mac to install without Xcode. It uses
#   iCloud's Production environment, where the development install uses
#   Development, and never touches /Applications or a running Thundermist. It
#   needs a Developer ID Application identity, a Developer ID provisioning
#   profile for this app (one left in ~/Downloads is installed for Xcode), and
#   notarization credentials saved with `xcrun notarytool store-credentials`
#   under the keychain profile thundermist-notary (or $THUNDERMIST_NOTARY_PROFILE).
#   --dmg --development makes the image from the development install instead:
#   signed with the Apple Development identity, on iCloud's Development
#   environment, so it shares the development install's iCloud data. It is not
#   notarized, and it opens only on the Macs its development profile lists:
#   register each Mac's Provisioning UDID at developer.apple.com, then make a
#   macOS App Development profile for this app that lists them and download it
#   (one left in ~/Downloads is installed for Xcode).

repository_root="${0:A:h:h}"
application_path="/Applications/Thundermist.app"
product_name="Thundermist"
bundle_identifier="com.theburl.thundermist"
team_id="K8SB434BHR"
engine_profile_root="/Thundermist/Ch"
engine_repository="pauljoda/Crest"
entitlements_source="CrestMac/Configuration/Thundermist.entitlements"
notary_profile="${THUNDERMIST_NOTARY_PROFILE:-thundermist-notary}"
derived_data_path="${THUNDERMIST_DERIVED_DATA:-$HOME/Library/Developer/Xcode/DerivedData/Thundermist}"
engine_cache_root="${CREST_ENGINE_CACHE:-$HOME/Library/Caches/Crest-local-release}"
lsregister="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

work_root="${THUNDERMIST_WORK_ROOT:-$HOME/Library/Caches/Thundermist}"
build_source="$work_root/source"

usage() {
  print -u2 "Usage: Scripts/install-thundermist.sh [--provision-only] [--no-install] [--no-open]"
  print -u2 "       Scripts/install-thundermist.sh --dmg [--development] [--output <path>.dmg]"
  exit 64
}

provision_only=false
install_when_done=true
open_when_done=true
make_disk_image=false
development_image=false
disk_image_path=""
installing_options=false
while (( $# > 0 )); do
  case "$1" in
    --provision-only) provision_only=true; installing_options=true ;;
    --no-install) install_when_done=false; installing_options=true ;;
    --no-open) open_when_done=false; installing_options=true ;;
    --dmg) make_disk_image=true ;;
    --development) development_image=true ;;
    --output) (( $# >= 2 )) || usage; disk_image_path="$2"; shift ;;
    *) usage ;;
  esac
  shift
done
if [[ "$make_disk_image" == true && "$installing_options" == true ]] \
  || [[ "$make_disk_image" != true && ( -n "$disk_image_path" || "$development_image" == true ) ]]; then
  usage
fi
# The Developer ID image, signed for every Mac and notarized.
developer_id_image=false
[[ "$make_disk_image" == true && "$development_image" != true ]] && developer_id_image=true

cd "$repository_root"

# A Developer ID image runs on any Mac, so it signs for iCloud's Production
# environment; the development install, and an image of it, stay on
# Development.
if [[ "$developer_id_image" == true ]]; then
  cloud_environment="Production"
  aps_environment="production"
else
  cloud_environment="Development"
  aps_environment="development"
fi
if [[ "$make_disk_image" == true ]]; then
  marketing_version="$(awk -F' *= *' '/^MARKETING_VERSION/ { print $2; exit }' Config/Version.xcconfig)"
  image_suffix=""
  [[ "$development_image" == true ]] && image_suffix="-Development"
  disk_image_path="${${disk_image_path:-$HOME/Desktop/$product_name-$marketing_version$image_suffix.dmg}:A}"
  if [[ "$disk_image_path" != *.dmg || "$disk_image_path" == "$repository_root"/* ]]; then
    print -u2 "The disk image needs a .dmg path outside the repository."
    exit 64
  fi
fi

release_root="$(mktemp -d "${TMPDIR%/}/thundermist-install.XXXXXX")"
resolved_entitlements="$release_root/entitlements.plist"
built_application_path="$release_root/product/Thundermist.app"
disk_image_staging_path="$release_root/disk-image/Thundermist.app"
provisioning_root="$release_root/provisioning"
provisioning_application_path="$provisioning_root/build/ThundermistProvisioning.app"
installation_staging_path="/Applications/.Thundermist-install-${$}.app"
previous_application_path="$release_root/Thundermist.previous.app"
installation_complete=false

cleanup() {
  if [[ -e "$installation_staging_path" ]]; then
    find "$installation_staging_path" -depth -delete 2>/dev/null || true
  fi
  if [[ "$installation_complete" != true && ! -e "$application_path" && -e "$previous_application_path" ]]; then
    mv "$previous_application_path" "$application_path" 2>/dev/null || true
  fi
  for intermediate in "$built_application_path" "$previous_application_path" "$provisioning_application_path" \
    "$disk_image_staging_path"; do
    [[ -e "$intermediate" ]] && "$lsregister" -u "$intermediate" >/dev/null 2>&1 || true
  done
  find "$release_root" -depth -delete 2>/dev/null || true
}
trap cleanup EXIT INT TERM HUP

# --- Signing profile: the newest current profile of a kind that grants this app.
# A development profile lists the Macs it runs on; a Developer ID profile runs
# on every Mac. It also writes the entitlements the app signs with. ---
find_profile() {
  python3 - "$1" "$team_id" "$bundle_identifier" "$entitlements_source" "$resolved_entitlements" \
    "$aps_environment" "$cloud_environment" <<'PYTHON'
import datetime
import pathlib
import plistlib
import shutil
import subprocess
import sys

kind, team, identifier, source, destination, aps, cloud = sys.argv[1:8]
application_id = f"{team}.{identifier}"
now = datetime.datetime.now(datetime.timezone.utc)
folder = pathlib.Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles"


def granted(path):
    decoded = subprocess.run(["security", "cms", "-D", "-i", str(path)], capture_output=True)
    if decoded.returncode != 0:
        return None
    profile = plistlib.loads(decoded.stdout)
    of_kind = profile.get("ProvisionsAllDevices", False) if kind == "developer-id" else "ProvisionedDevices" in profile
    current = profile["ExpirationDate"].replace(tzinfo=datetime.timezone.utc) > now
    grants = profile.get("Entitlements", {}).get("com.apple.application-identifier") == application_id
    return profile if of_kind and current and grants else None


def newest(paths):
    found = None
    for path in paths:
        profile = granted(path)
        if profile and (found is None or profile["CreationDate"] > found[1]["CreationDate"]):
            found = (path, profile)
    return found


found = newest(folder.iterdir()) if folder.is_dir() else None
# A newer profile as the developer website downloads it, as one listing more
# Macs, is installed where Xcode keeps profiles so later builds find it too.
downloaded = newest((pathlib.Path.home() / "Downloads").glob("*.provisionprofile"))
if downloaded and (found is None or downloaded[1]["CreationDate"] > found[1]["CreationDate"]):
    folder.mkdir(parents=True, exist_ok=True)
    installed = folder / f"{downloaded[1]['UUID']}.provisionprofile"
    shutil.copy2(downloaded[0], installed)
    print(f"Installed {downloaded[0].name} from Downloads in {folder}.", file=sys.stderr)
    found = (installed, downloaded[1])
if found is None:
    sys.exit(1)
text = pathlib.Path(source).read_text()
for name, value in (("AppIdentifierPrefix", f"{team}."), ("APS_ENVIRONMENT", aps),
                    ("ICLOUD_CONTAINER_ENVIRONMENT", cloud)):
    text = text.replace(f"$({name})", value)
pathlib.Path(destination).write_text(text)
print(found[0])
PYTHON
}

if [[ "$developer_id_image" == true ]]; then
  # --- Developer ID: everything a notarized image needs, checked before the
  # long build. ---
  typeset -a missing
  signing_identity_hash="$(
    security find-identity -v -p codesigning \
      | awk -v team="($team_id)" '/"Developer ID Application: / && index($0, team) { print $2; exit }'
  )"
  if [[ -z "$signing_identity_hash" ]]; then
    missing+=("No Developer ID Application identity of team $team_id is installed. In Xcode, open Settings > Accounts > Manage Certificates and add a Developer ID Application certificate.")
  fi
  profile_path="$(find_profile developer-id)" || profile_path=""
  if [[ -z "$profile_path" ]]; then
    missing+=("No current Developer ID provisioning profile grants $team_id.$bundle_identifier, here or in ~/Downloads. Make one at developer.apple.com under Profiles > Developer ID for $bundle_identifier and download it.")
  fi
  if ! xcrun notarytool history --keychain-profile "$notary_profile" >/dev/null 2>&1; then
    missing+=("Apple's notary service doesn't accept the keychain profile $notary_profile, or can't be reached. Save the login with: xcrun notarytool store-credentials $notary_profile --apple-id <Apple ID> --team-id $team_id")
  fi
  if (( ${#missing} > 0 )); then
    print -u2 "Thundermist can't make a disk image yet:"
    for reason in "${missing[@]}"; do print -u2 -- "- $reason"; done
    exit 1
  fi
  print "Using provisioning profile ${profile_path:t}."
else
  # --- Development: a throwaway app with the same identity and entitlements
  # has Xcode's signed-in account register the App ID, its capabilities and a
  # development profile, without compiling the browser. ---
  print "Provisioning $bundle_identifier..."
  mkdir -p "$provisioning_root"
  cp "$entitlements_source" "$provisioning_root/Thundermist.entitlements"
  print 'print("Thundermist provisioning stub")' > "$provisioning_root/main.swift"
  cat > "$provisioning_root/project.yml" <<YAML
name: ThundermistProvisioning
targets:
  ThundermistProvisioning:
    type: application
    platform: macOS
    deploymentTarget: "26.1"
    sources: [main.swift]
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: $bundle_identifier
        DEVELOPMENT_TEAM: $team_id
        CODE_SIGN_STYLE: Automatic
        CODE_SIGN_IDENTITY: Apple Development
        CODE_SIGN_ENTITLEMENTS: Thundermist.entitlements
        APS_ENVIRONMENT: $aps_environment
        ICLOUD_CONTAINER_ENVIRONMENT: $cloud_environment
        ENABLE_HARDENED_RUNTIME: YES
        GENERATE_INFOPLIST_FILE: YES
        SWIFT_VERSION: "6.0"
YAML
  (cd "$provisioning_root" && xcodegen generate --quiet)
  xcodebuild build \
    -quiet \
    -project "$provisioning_root/ThundermistProvisioning.xcodeproj" \
    -target ThundermistProvisioning \
    -configuration Debug \
    -allowProvisioningUpdates \
    -allowProvisioningDeviceRegistration \
    SYMROOT="$provisioning_root/build" \
    CONFIGURATION_BUILD_DIR="$provisioning_root/build"

  if ! profile_path="$(find_profile development)"; then
    print -u2 "No current provisioning profile grants $team_id.$bundle_identifier"
    exit 1
  fi
  print "Using provisioning profile ${profile_path:t}."
  if [[ "$development_image" == true ]]; then
    profile_macs="$(security cms -D -i "$profile_path" | plutil -extract ProvisionedDevices raw -o - -)"
    if (( profile_macs < 2 )); then
      print -u2 "${profile_path:t} lists only this Mac, so an image of it opens nowhere else. Register the other Mac's Provisioning UDID at developer.apple.com under Devices, make a macOS App Development profile for $bundle_identifier that lists it, and download it."
      exit 1
    fi
    print "The image opens on the $profile_macs Macs that profile lists."
  fi
  if [[ "$provision_only" == true ]]; then
    print "$bundle_identifier is registered with team $team_id."
    exit 0
  fi

  signing_identity_hash="$(
    security find-identity -v -p codesigning | awk '/Apple Development: / { print $2; exit }'
  )"
  if [[ -z "$signing_identity_hash" ]]; then
    print -u2 "No valid Apple Development signing identity is installed."
    exit 1
  fi
fi

export CREST_DOTNET="${CREST_DOTNET:-$HOME/.dotnet/dotnet}"
if [[ ! -x "$CREST_DOTNET" ]]; then
  print -u2 "Run Scripts/control-plane/install-dotnet.sh for the SDK in CrestCore/global.json."
  exit 1
fi

# --- Chromium engine: resolved before the builds, cached by its tag. ---
engine_tag="$(python3 Scripts/control-plane/chromium_engine.py tag)"
engine_asset="$(python3 Scripts/control-plane/chromium_engine.py asset)"
engine_path="$engine_cache_root/$engine_tag/Chromium.app"
if [[ ! -d "$engine_path" ]]; then
  print "Downloading Chromium engine $engine_tag..."
  download_path="$release_root/engine-download"
  mkdir -p "$download_path"
  if ! gh release download "$engine_tag" --repo "$engine_repository" \
    --pattern "$engine_asset" --pattern "${engine_asset}.sha256" --dir "$download_path"; then
    print -u2 "$engine_repository has not published an engine for this checkout ($engine_tag)."
    exit 1
  fi
  (cd "$download_path" && shasum -a 256 -c "${engine_asset}.sha256")
  ditto -x -k "$download_path/$engine_asset" "$download_path/extracted"
  [[ -d "$download_path/extracted/Chromium.app" ]]
  mkdir -p "$engine_cache_root"
  find "$engine_cache_root" -mindepth 1 -maxdepth 1 -name 'chromium-engine-*' -exec rm -rf {} + 2>/dev/null || true
  mv "$download_path/extracted" "$engine_cache_root/$engine_tag"
fi

# --- Source: everything below builds from the renamed copy. ---
print "Preparing source in $build_source..."
mkdir -p "$build_source"
rsync -a --delete --exclude .git --exclude 'CrestCore/**/bin/' --exclude 'CrestCore/**/obj/' \
  "$repository_root/" "$build_source/"
python3 "$repository_root/Scripts/thundermist-rebrand.py" "$build_source"
# Thundermist's waterfall icon takes the place of Crest's, keeping Crest's name
# so every target and the packager find it as before.
rm -rf "$build_source/CrestShared/Resources/CrestIcon/Crest.icon"
ditto "$repository_root/Thundermist/Thundermist.icon" "$build_source/CrestShared/Resources/CrestIcon/Crest.icon"
cd "$build_source"
# The contract fingerprint hashes the renamed text, so refresh the generated files.
(cd CrestCore && "$CREST_DOTNET" run --project tools/CrestCore.Generator --nologo -- --root "$build_source" >/dev/null)
# Generate the project here too, so new files need no change to the tracked one.
xcodegen generate --quiet

# --- Native core and interface. ---
build_number="$(date +%Y%m%d%H%M)"
print "Building $product_name $build_number with $engine_tag..."
(cd CrestCore && SDKROOT="$(xcrun --sdk macosx --show-sdk-path)" \
  "$CREST_DOTNET" publish src/CrestCore.Native -c Release -r osx-arm64 --nologo -v quiet)
core_library="$PWD/CrestCore/src/CrestCore.Native/bin/Release/net10.0/osx-arm64/publish/CrestCore.Native.dylib"
[[ -f "$core_library" ]]
if otool -L "$core_library" | grep -q '/opt/homebrew'; then
  print -u2 "The core links Homebrew libraries; build it with the pinned SDK, not Homebrew's."
  exit 1
fi

xcodebuild build \
  -quiet \
  -project Crest.xcodeproj \
  -scheme CrestChromiumUIProduct \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$derived_data_path" \
  CURRENT_PROJECT_VERSION="$build_number" \
  CODE_SIGNING_ALLOWED=NO
ui_framework="$derived_data_path/Build/Products/Release/CrestChromiumUIProduct.framework"
[[ -d "$ui_framework" ]]
for entry in crest_chromium_ui_start crest_native_host_run; do
  if ! nm -gU "$ui_framework/CrestChromiumUIProduct" | grep -q "_${entry}\$"; then
    print -u2 "CrestChromiumUIProduct does not export $entry."
    exit 1
  fi
done

# --- Package and sign. ---
mkdir -p "${built_application_path:h}"
python3 Scripts/control-plane/package-chromium-host.py \
  --browser "$engine_path" \
  --product \
  --distribution \
  --product-identity "$bundle_identifier" \
  --product-name "$product_name" \
  --engine-profile-root "$engine_profile_root" \
  --cloud-environment "$cloud_environment" \
  --ui "$ui_framework" \
  --core "$core_library" \
  --entitlements "$resolved_entitlements" \
  --provisioning-profile "$profile_path" \
  --signing-identity "$signing_identity_hash" \
  --output "$built_application_path"

codesign --verify --deep --strict --verbose=2 "$built_application_path"
[[ "$(defaults read "$built_application_path/Contents/Info" CFBundleIdentifier)" == "$bundle_identifier" ]]

if [[ "$make_disk_image" == true ]]; then
  # --- A Developer ID image notarizes the app, then a signed, notarized image
  # holding it, as Crest's release does (.github/workflows/release.yml). A
  # development image holds the development-signed app as it is. ---
  signed_entitlements="$release_root/signed-entitlements.plist"
  codesign -d --entitlements :- "$built_application_path" > "$signed_entitlements" 2>/dev/null
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.developer.icloud-container-environment' "$signed_entitlements")" == "$cloud_environment" ]]
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.developer.aps-environment' "$signed_entitlements")" == "$aps_environment" ]]

  notarize() {
    local submission
    print "Notarizing ${1:t}..."
    submission="$(xcrun notarytool submit "$1" --keychain-profile "$notary_profile" --wait --output-format json)"
    local submission_status="$(print -r -- "$submission" | python3 -c 'import json, sys; print(json.load(sys.stdin).get("status", ""))')"
    if [[ "$submission_status" != "Accepted" ]]; then
      local submission_id="$(print -r -- "$submission" | python3 -c 'import json, sys; print(json.load(sys.stdin).get("id", ""))')"
      print -u2 "Apple's notary service answered ${submission_status:-nothing} for ${1:t}."
      [[ -n "$submission_id" ]] && xcrun notarytool log "$submission_id" --keychain-profile "$notary_profile" >&2 || true
      exit 1
    fi
  }

  if [[ "$developer_id_image" == true ]]; then
    application_archive="$release_root/Thundermist-notarization.zip"
    ditto -c -k --sequesterRsrc --keepParent "$built_application_path" "$application_archive"
    notarize "$application_archive"
    xcrun stapler staple "$built_application_path"
    xcrun stapler validate "$built_application_path"
    spctl --assess --type execute --verbose=4 "$built_application_path"
  fi

  disk_image="$release_root/$product_name.dmg"
  mkdir -p "${disk_image_staging_path:h}"
  ditto "$built_application_path" "$disk_image_staging_path"
  ln -s /Applications "${disk_image_staging_path:h}/Applications"
  diskutil image create from --volumeName "$product_name" --format ULFO "${disk_image_staging_path:h}" "$disk_image"
  if [[ "$developer_id_image" == true ]]; then
    codesign --force --timestamp --sign "$signing_identity_hash" "$disk_image"
    notarize "$disk_image"
    xcrun stapler staple "$disk_image"
    xcrun stapler validate "$disk_image"
    spctl --assess --type open --context context:primary-signature --verbose=4 "$disk_image"
  fi

  mkdir -p "${disk_image_path:h}"
  [[ -e "$disk_image_path" ]] && print "Replacing ${disk_image_path:t}."
  mv -f "$disk_image" "$disk_image_path"
  if [[ "$developer_id_image" == true ]]; then
    print "Made $product_name $build_number at $disk_image_path with $engine_tag. Open it on any Apple Silicon Mac and drag $product_name to Applications."
  else
    print "Made development $product_name $build_number at $disk_image_path with $engine_tag. It opens only on the $profile_macs Macs ${profile_path:t} lists; the first time, macOS asks for Open Anyway in System Settings > Privacy & Security."
  fi
  exit 0
fi

if [[ "$install_when_done" != true ]]; then
  kept_application_path="$work_root/Thundermist.app"
  [[ -e "$kept_application_path" ]] && find "$kept_application_path" -depth -delete
  ditto "$built_application_path" "$kept_application_path"
  "$lsregister" -u "$kept_application_path" >/dev/null 2>&1 || true
  print "Built $product_name $build_number at $kept_application_path; nothing was installed."
  exit 0
fi

# --- Install. Only this app's own process is ever asked to quit. ---
installed_pattern="^${application_path}/Contents/MacOS/"
if pgrep -f "$installed_pattern" >/dev/null 2>&1; then
  osascript -e "tell application id \"$bundle_identifier\" to quit"
  for _ in {1..100}; do
    pgrep -f "$installed_pattern" >/dev/null 2>&1 || break
    sleep 0.1
  done
fi
if pgrep -f "$installed_pattern" >/dev/null 2>&1; then
  print -u2 "$product_name did not quit; the existing application was not replaced."
  exit 1
fi

ditto "$built_application_path" "$installation_staging_path"
codesign --verify --deep --strict --verbose=2 "$installation_staging_path"
if [[ -e "$application_path" ]]; then
  mv "$application_path" "$previous_application_path"
fi
mv "$installation_staging_path" "$application_path"
installation_complete=true

"$lsregister" -f "$application_path" >/dev/null 2>&1 || true
print "Installed $product_name $build_number at $application_path with $engine_tag."
if [[ "$open_when_done" == true ]]; then
  open "$application_path"
fi

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
#   --no-install leaves the signed app in ~/Library/Caches/Thundermist and does
#   not touch /Applications or a running Thundermist.

repository_root="${0:A:h:h}"
application_path="/Applications/Thundermist.app"
product_name="Thundermist"
bundle_identifier="com.theburl.thundermist"
team_id="K8SB434BHR"
engine_profile_root="/Thundermist/Ch"
engine_repository="pauljoda/Crest"
entitlements_source="CrestMac/Configuration/Thundermist.entitlements"
cloud_environment="Development"
aps_environment="development"
derived_data_path="${THUNDERMIST_DERIVED_DATA:-$HOME/Library/Developer/Xcode/DerivedData/Thundermist}"
engine_cache_root="${CREST_ENGINE_CACHE:-$HOME/Library/Caches/Crest-local-release}"
lsregister="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

work_root="${THUNDERMIST_WORK_ROOT:-$HOME/Library/Caches/Thundermist}"
build_source="$work_root/source"

provision_only=false
install_when_done=true
open_when_done=true
for argument in "$@"; do
  case "$argument" in
    --provision-only) provision_only=true ;;
    --no-install) install_when_done=false ;;
    --no-open) open_when_done=false ;;
    *) print -u2 "Usage: Scripts/install-thundermist.sh [--provision-only] [--no-install] [--no-open]"; exit 64 ;;
  esac
done

cd "$repository_root"

release_root="$(mktemp -d "${TMPDIR%/}/thundermist-install.XXXXXX")"
built_application_path="$release_root/product/Thundermist.app"
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
  for intermediate in "$built_application_path" "$previous_application_path" "$provisioning_application_path"; do
    [[ -e "$intermediate" ]] && "$lsregister" -u "$intermediate" >/dev/null 2>&1 || true
  done
  find "$release_root" -depth -delete 2>/dev/null || true
}
trap cleanup EXIT INT TERM HUP

# --- Signing: a throwaway app with the same identity and entitlements has Xcode's
# signed-in account register the App ID, its capabilities and a development
# profile, without compiling the browser. ---
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

resolved_entitlements="$release_root/entitlements.plist"
profile_path="$(python3 - "$team_id" "$bundle_identifier" "$entitlements_source" "$resolved_entitlements" \
  "$aps_environment" "$cloud_environment" <<'PYTHON'
import datetime
import pathlib
import plistlib
import subprocess
import sys

team, identifier, source, destination, aps, cloud = sys.argv[1:7]
application_id = f"{team}.{identifier}"
newest = None
folder = pathlib.Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles"
for path in folder.iterdir():
    decoded = subprocess.run(["security", "cms", "-D", "-i", str(path)], capture_output=True)
    if decoded.returncode != 0:
        continue
    profile = plistlib.loads(decoded.stdout)
    expires = profile["ExpirationDate"].replace(tzinfo=datetime.timezone.utc)
    if (profile.get("Entitlements", {}).get("com.apple.application-identifier") == application_id
            and expires > datetime.datetime.now(datetime.timezone.utc)
            and (newest is None or profile["CreationDate"] > newest[1])):
        newest = (path, profile["CreationDate"])
if newest is None:
    sys.exit(f"No current provisioning profile grants {application_id}")
text = pathlib.Path(source).read_text()
for name, value in (("AppIdentifierPrefix", f"{team}."), ("APS_ENVIRONMENT", aps),
                    ("ICLOUD_CONTAINER_ENVIRONMENT", cloud)):
    text = text.replace(f"$({name})", value)
pathlib.Path(destination).write_text(text)
print(newest[0])
PYTHON
)"
print "Using provisioning profile ${profile_path:t}."
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

#!/bin/zsh
set -euo pipefail

# Merges upstream Crest into the thundermist branch, tests the core, and rebuilds
# and installs Thundermist. This is how Thundermist gets Chromium security fixes,
# because it has no automatic updates.
#
# It resolves the conflicts every merge of this fork can hit on its own: the
# version, the release notes, the generated contract files and the Xcode project,
# which it regenerates so it lists the fork's files too. Any other conflict
# cancels the merge and leaves the branch as it was.
#
# Usage: Scripts/update-thundermist.sh [--no-install] [--no-open]

repository_root="${0:A:h:h}"
branch="thundermist"
upstream_ref="upstream/main"
engine_repository="pauljoda/Crest"
export CREST_DOTNET="${CREST_DOTNET:-$HOME/.dotnet/dotnet}"

install_when_done=true
typeset -a install_arguments
for argument in "$@"; do
  case "$argument" in
    --no-install) install_when_done=false ;;
    --no-open) install_arguments+=("$argument") ;;
    *) print -u2 "Usage: Scripts/update-thundermist.sh [--no-install] [--no-open]"; exit 64 ;;
  esac
done

cd "$repository_root"

if [[ "$(git branch --show-current)" != "$branch" ]]; then
  print -u2 "Switch to the $branch branch first."
  exit 1
fi
if [[ -n "$(git status --porcelain)" ]]; then
  print -u2 "Commit or set aside the changes in this checkout first."
  exit 1
fi
if [[ ! -x "$CREST_DOTNET" ]]; then
  print -u2 "Run Scripts/control-plane/install-dotnet.sh for the SDK in CrestCore/global.json."
  exit 1
fi
if ! command -v xcodegen >/dev/null 2>&1; then
  print -u2 "Install XcodeGen first (brew install xcodegen)."
  exit 1
fi

git fetch --quiet upstream
behind="$(git rev-list --count "HEAD..$upstream_ref")"
if [[ "$behind" == 0 ]]; then
  print "Already has everything from Crest."
else
  print "Merging $behind commit(s) from Crest..."
  merging=true
  cancel() {
    if [[ "$merging" == true ]]; then
      git merge --abort 2>/dev/null || true
      print -u2 "Merge cancelled; $branch is unchanged."
    fi
  }
  trap cancel EXIT INT TERM HUP

  git merge --no-commit --no-ff "$upstream_ref" >/dev/null 2>&1 || true

  # Conflicts with a known answer. Generated files come back from the generator below.
  python3 - <<'PYTHON'
import json
import re
import subprocess

def stage(number, path):
    return subprocess.run(["git", "show", f":{number}:{path}"], capture_output=True, text=True, check=True).stdout

def version(text):
    return tuple(int(part) for part in re.search(r"MARKETING_VERSION\s*=\s*([0-9.]+)", text).group(1).split("."))

generated = {
    "Crest.xcodeproj/project.pbxproj",
    "CrestContracts/include/crest_contracts.h",
    "CrestContracts/include/crest_engine_contract.h",
    "CrestCore/src/CrestCore.Native/Generated/ContractCodec.g.cs",
    "CrestShared/Infrastructure/Core/Generated/CoreCodec.generated.swift",
    "CrestShared/Infrastructure/Core/Generated/CoreContracts.generated.swift",
}
# Upstream's fix wins over the fork's copy of the same one-line test repair.
take_upstream = generated | {"CrestTests/SpaceScrollGestureTests.swift"}

conflicts = subprocess.run(["git", "diff", "--name-only", "--diff-filter=U"], capture_output=True, text=True, check=True)
for path in conflicts.stdout.split():
    if path == "Documentation/ReleaseNotes.json":
        ours, theirs = json.loads(stage(2, path)), json.loads(stage(3, path))
        for identifier, entry in ours["entries"].items():
            theirs["entries"].setdefault(identifier, entry)
        with open(path, "w", encoding="utf-8") as stream:
            json.dump(theirs, stream, ensure_ascii=False, indent=2)
            stream.write("\n")
    elif path == "Config/Version.xcconfig":
        newest = max(stage(2, path), stage(3, path), key=version)
        with open(path, "w", encoding="utf-8") as stream:
            stream.write(newest)
    elif path in take_upstream:
        subprocess.run(["git", "checkout", "--theirs", "--", path], check=True)
    else:
        continue
    subprocess.run(["git", "add", "--", path], check=True)
PYTHON

  remaining="$(git diff --name-only --diff-filter=U)"
  if [[ -n "$remaining" ]]; then
    print -u2 "These files need a person to merge them:"
    print -u2 -- "$remaining"
    exit 1
  fi

  # The contract fingerprint hashes the source, so refresh it after any merge.
  (cd CrestCore && "$CREST_DOTNET" run --project tools/CrestCore.Generator --nologo -- --root "$repository_root" >/dev/null)
  git add -- CrestContracts/include CrestCore/src/CrestCore.Native/Generated CrestShared/Infrastructure/Core/Generated
  # Upstream's project lacks the fork's own files, so build it from project.yml.
  xcodegen generate --quiet
  git add -- Crest.xcodeproj
  Scripts/check-version.sh --static >/dev/null

  # The engine is prebuilt, so its release has to exist before this can build.
  engine_tag="$(python3 Scripts/control-plane/chromium_engine.py tag)"
  if ! gh release view "$engine_tag" --repo "$engine_repository" >/dev/null 2>&1; then
    print -u2 "Crest hasn't published $engine_tag for this code yet. Try again later."
    exit 1
  fi

  print "Testing the core..."
  (cd CrestCore && "$CREST_DOTNET" test tests/CrestCore.Tests --nologo -v quiet)

  git commit --quiet -F - <<MESSAGE
Merge Crest's latest changes into Thundermist

Brings in $behind commit(s) from $upstream_ref, using Chromium engine $engine_tag.
${THUNDERMIST_COMMIT_TRAILER:-}
MESSAGE
  merging=false
  trap - EXIT INT TERM HUP
  print "Merged. Push $branch to keep your fork current."
fi

if [[ "$install_when_done" == true ]]; then
  exec Scripts/install-thundermist.sh "${install_arguments[@]}"
fi

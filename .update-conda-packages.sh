#!/usr/bin/env bash

set -euo pipefail

DRY_RUN=0
TOOL=""

# Parse --dry-run flag
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

# Detect conda tool
for cmd in micromamba mamba conda; do
  if command -v "$cmd" &>/dev/null; then
    TOOL="$cmd"
    break
  fi
done

if [[ -z "$TOOL" ]]; then
  echo "❌ No conda-compatible tool (micromamba, mamba, conda) found in PATH."
  exit 1
fi

echo "🔍 Using $TOOL to fetch latest versions from conda-forge..."

CHANNEL="conda-forge"
CHANGED=0

for req_file in */requirements.txt; do
  [ -f "$req_file" ] || continue

  read -r first_line < "$req_file"
  pkg=$(echo "$first_line" | cut -d= -f1)

  echo "📦 Checking latest version for $pkg in $req_file..."

  latest_version=$($TOOL search "$pkg" --channel "$CHANNEL" --json | \
    jq -r ".[\"result\"][\"pkgs\"][0]| .version")

  if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
    echo "⚠️  Could not determine latest version for $pkg"
    continue
  fi

  new_line="${pkg}=${latest_version}"

  if [[ "$first_line" != "$new_line" ]]; then
    echo "🔄 Would update $pkg: $first_line → $new_line"
    if [[ $DRY_RUN -eq 0 ]]; then
      tail -n +2 "$req_file" > tmp.txt
      echo "$new_line" > "$req_file"
      cat tmp.txt >> "$req_file"
      rm tmp.txt
      CHANGED=1
    fi
  else
    echo "✅ $pkg is up-to-date ($latest_version)"
  fi
done

if [[ $CHANGED -eq 1 ]]; then
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "💡 Dry run mode: no changes were written."
  else
    echo "📦 Changes detected, committing and pushing..."
    BRANCH="conda-update/$(date +%F)"
    git config user.name "conda-bot"
    git config user.email "bot@conda-updater"
    git checkout -b $BRANCH
    git add */requirements.txt
    git commit -m "Update conda package versions to latest available"
    git push origin $BRANCH
  fi
else
  echo "✨ All packages already up-to-date."
fi

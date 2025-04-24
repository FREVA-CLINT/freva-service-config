#!/usr/bin/env bash
set -euo pipefail

# Detect if we are running inside GitHub Actions
if [[ -z "${GITHUB_ACTIONS:-}" ]]; then
  echo "💡 Running outside CI: dry run mode enabled."
  DRY_RUN=1
else
  DRY_RUN=0
fi

# Detect conda-compatible tool
TOOL=""
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

CHANNEL="conda-forge"
echo "🔍 Using $TOOL to check latest versions from $CHANNEL..."

# Iterate over each requirements.txt file
for req_file in */requirements.txt; do
  [ -f "$req_file" ] || continue

  service=$(dirname "$req_file")
  read -r first_line < "$req_file"
  pkg=$(echo "$first_line" | cut -d= -f1)
  old_version=$(echo "$first_line" | cut -d= -f2)

  echo "📦 Checking latest version of $pkg for $service..."

  latest_version=$($TOOL search "$pkg" --channel "$CHANNEL" --json | \
    jq -r '."result"."pkgs"[0].version')

  if [[ -z "$latest_version" || "$latest_version" == "null" ]]; then
    echo "⚠️  Could not determine latest version for $pkg"
    continue
  fi

  if [[ "$latest_version" == "$old_version" ]]; then
    echo "✅ $pkg is up-to-date ($latest_version)"
    continue
  fi

  echo "🔄 $pkg: $old_version → $latest_version"

  BRANCH="bump-${pkg}-${old_version}-${latest_version}"
  PR_TITLE="⬆️ bump ${pkg}: ${old_version} → ${latest_version}"
  PR_BODY="This PR updates **${pkg}** from version \`${old_version}\` to \`${latest_version}\` in \`${req_file}\`."

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "💡 [Dry run] Would create PR: $PR_TITLE"
    continue
  fi

  # Check if PR already exists
  if gh pr list --state open --head "$BRANCH" | grep -q "$BRANCH"; then
    echo "ℹ️ PR already exists: $BRANCH — skipping"
    continue
  fi

  # Create temp branch and commit
  git switch -c "$BRANCH"
  tail -n +2 "$req_file" > tmp.txt
  echo "${pkg}=${latest_version}" > "$req_file"
  cat tmp.txt >> "$req_file"
  rm tmp.txt

  git config user.name "conda-bot"
  git config user.email "bot@conda-updater"
  git commit -am "$PR_TITLE"
  git push origin "$BRANCH"

  # Create pull request
  gh pr create \
    --title "$PR_TITLE" \
    --body "$PR_BODY" \
    --head "$BRANCH" \
    --base main

  # Switch back to main and clean up
  git switch main
  git branch -D "$BRANCH"
done

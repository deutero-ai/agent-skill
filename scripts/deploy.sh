#!/usr/bin/env bash
# Sync the Deutero skills from the dashboard repo into this repo, bump the
# manifest versions to the latest CHANGELOG entry, commit and push.
#
# Usage: scripts/deploy.sh [-n] [-y] [-m "commit subject"] [-s SOURCE_DIR]
#   -n  dry run: sync and show the diff, but don't commit or push
#   -y  push without asking
#   -m  commit subject (default: "Sync skills to <version>")
#   -s  source directory (default: $DEUTERO_SKILLS_SRC or the dashboard checkout)
set -euo pipefail

SRC="${DEUTERO_SKILLS_SRC:-$HOME/deutero-prod/deutero-dashboard/static/skills/deutero}"
DRY_RUN=0
ASSUME_YES=0
SUBJECT=""

while getopts "nym:s:h" opt; do
  case "$opt" in
    n) DRY_RUN=1 ;;
    y) ASSUME_YES=1 ;;
    m) SUBJECT="$OPTARG" ;;
    s) SRC="$OPTARG" ;;
    *) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
  esac
done

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$REPO/deutero-interview-research"
MANIFESTS=(
  "$REPO/.claude-plugin/marketplace.json"
  "$DEST/.claude-plugin/plugin.json"
  "$DEST/plugin.json"
)

die() { echo "error: $*" >&2; exit 1; }

[[ -f "$SRC/CHANGELOG.md" && -d "$SRC/skills" ]] || die "no skills found at $SRC"
cd "$REPO"

# Start from a clean, up-to-date main so the commit holds only the sync.
[[ "$(git branch --show-current)" == main ]] || die "not on main"
[[ -z "$(git status --porcelain)" ]] || die "working tree is not clean"
git pull --ff-only --quiet

SRC_REPO="$(git -C "$SRC" rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -n "$SRC_REPO" && -n "$(git -C "$SRC_REPO" status --porcelain -- "$SRC")" ]]; then
  echo "warning: $SRC has uncommitted changes in the dashboard repo" >&2
fi

OLD_VERSION="$(jq -r .version "$DEST/plugin.json")"
NEW_VERSION="$(sed -n 's/^## \([0-9][0-9.]*\).*/\1/p' "$SRC/CHANGELOG.md" | head -1)"
[[ -n "$NEW_VERSION" ]] || die "no version heading in $SRC/CHANGELOG.md"

# No --delete: this repo's manifests (plugin.json, mcp.json, .claude-plugin/)
# don't exist in the dashboard copy and must survive the sync.
rsync -a \
  --exclude .DS_Store \
  --exclude plugin.json \
  --exclude mcp.json \
  --exclude .claude-plugin/ \
  "$SRC/" "$DEST/"

# The repo root also carries skills/<name>/ so `hermes skills tap add deutero-ai/agent-skill`
# works — TapsManager hardcodes the tap path to "skills/" and walks one level under it — and so
# skills.sh lists the skills at their bare slugs. Same source, same commit, so the copies cannot
# drift; --delete keeps it a strict mirror.
rsync -a --delete \
  --exclude .DS_Store \
  "$SRC/skills/" "$REPO/skills/"

for f in "${MANIFESTS[@]}"; do
  sed -i '' -E "s/(\"version\": *)\"[^\"]*\"/\1\"$NEW_VERSION\"/" "$f"
done

# Keep the root README's tool count in step with the inventory.
TOOL_COUNT="$(sed -n 's/^\([0-9][0-9]*\) tools\..*/\1/p' \
  "$DEST/skills/deutero-setup/references/mcp-clients.md" | head -1)"
if [[ -n "$TOOL_COUNT" ]]; then
  sed -i '' -E "s/It has [0-9]+ tools/It has $TOOL_COUNT tools/" "$REPO/README.md"
fi

git add -A
if git diff --cached --quiet; then
  echo "Already up to date at $OLD_VERSION."
  exit 0
fi

echo "Syncing $OLD_VERSION -> $NEW_VERSION"
git diff --cached --stat
echo
echo "Check the root README by hand: the MCP tools table, the dashboard-only"
echo "FAQ answer and the skill descriptions aren't updated by this script."

if (( DRY_RUN )); then
  git reset --quiet
  echo
  echo "Dry run: changes left unstaged in the working tree, nothing committed."
  exit 0
fi

# Commit body: every CHANGELOG section newer than the version we had.
BODY="$(awk -v old="## $OLD_VERSION" '
  index($0, old) == 1 { exit }
  /^## / { started = 1 }
  started' "$DEST/CHANGELOG.md")"
git commit --quiet -m "${SUBJECT:-Sync skills to $NEW_VERSION}" -m "$BODY"
git log -1 --stat --format='%h %s'

if (( ! ASSUME_YES )); then
  read -r -p "Push to $(git rev-parse --abbrev-ref '@{u}')? [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]] || { echo "Not pushed. Run 'git push' when ready."; exit 0; }
fi
git push --quiet
echo "Pushed $NEW_VERSION."

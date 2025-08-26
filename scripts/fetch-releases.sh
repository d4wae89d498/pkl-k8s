#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $SCRIPT_DIR/settings.sh

# Read repository keys from settings
REPO_KEYS=$(echo "$SETTINGS" | jq -r '.releases | keys | .[]')


# ---- Main loop per repo key ----
for REPO_KEY in $REPO_KEYS; do
  TAG=$(echo "$SETTINGS" | jq -r ".releases.\"$REPO_KEY\".tag")
  ALLOW_PRERELEASE=$(echo "$SETTINGS" | jq -r ".releases.\"$REPO_KEY\".allowPrerelease")
  REPO="somecompany-team/$REPO_KEY"
  echo "📦 Processing $REPO_KEY ($REPO)..."
  
  # Fetch release data
  releases_json=$(gh api "repos/$REPO/releases?per_page=100")

  # Use specified tag if not "latest"
  if [[ "$TAG" != "latest" ]]; then
    found_tag=$(echo "$releases_json" | jq -r --arg TAG "$TAG" '.[] | select(.tag_name == $TAG) | .tag_name')
    if [[ -z "$found_tag" ]]; then
      echo "❌ Tag '$TAG' not found in $REPO"
      continue
    fi
    final_tag="$TAG"
    echo "🎯 Using fixed tag for $REPO: $final_tag"
  else
    # Determine latest release or prerelease
    latest_release=$(echo "$releases_json" | jq -r '[.[] | select(.prerelease == false)][0]')
    latest_prerelease=$(echo "$releases_json" | jq -r '[.[] | select(.prerelease == true)][0]')

    tag_release=$(echo "$latest_release" | jq -r '.tag_name // empty')
    date_release=$(echo "$latest_release" | jq -r '.published_at // empty')

    tag_prerelease=$(echo "$latest_prerelease" | jq -r '.tag_name // empty')
    date_prerelease=$(echo "$latest_prerelease" | jq -r '.published_at // empty')

    if [[ "$ALLOW_PRERELEASE" == "true" && -n "$date_prerelease" && "$date_prerelease" > "$date_release" ]]; then
      final_tag="$tag_prerelease"
      echo "🚀 Selected pre-release tag: $final_tag"
    elif [[ -n "$tag_release" ]]; then
      final_tag="$tag_release"
      echo "🎯 Selected release tag: $final_tag"
    else
      echo "⚠️  No valid releases found for $REPO"
      continue
    fi
  fi

  # Prepare directory and download assets
  REPO_NAME=$(basename "$REPO")
  DOWNLOAD_DIR="$SCRIPT_DIR/../releases/$REPO_NAME/$final_tag"
  mkdir -p "$DOWNLOAD_DIR"

  echo "⬇️  Downloading assets to $DOWNLOAD_DIR..."
  gh release download "$final_tag" --repo "$REPO" --dir "$DOWNLOAD_DIR" --clobber

  echo "🔗 Updating latest → $final_tag"
  ln -sfn "$DOWNLOAD_DIR" "$SCRIPT_DIR/../releases/$REPO_NAME/latest"

  echo "✅ Done with $REPO"
  echo ""
done

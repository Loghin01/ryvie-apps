#!/bin/bash
# ----------------------------------------------------------
# Script: generate_apps_json.sh
# Description: Generate apps.json by merging metadata from each
#              t-apps.yml and constructing image URLs from jsDelivr.
# ----------------------------------------------------------

set -e

# ------------------------------
# Check dependencies: jq & yq
# ------------------------------
command -v jq >/dev/null 2>&1 || {
  echo "❌ jq is not installed. Installing..."
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt update && sudo apt install -y jq
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew install jq
  else
    echo "⚠️ Unsupported OS. Please install jq manually."
    exit 1
  fi
}

command -v yq >/dev/null 2>&1 || {
  echo "❌ yq is not installed. Installing..."
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt update && sudo apt install -y yq
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew install yq
  else
    echo "⚠️ Unsupported OS. Please install yq manually."
    exit 1
  fi
}

APPS_DIR="apps"
OUTPUT_FILE="apps.json"
GITHUB_REPO="ryvie/ryvie-apps"
BRANCH="main"

echo "🧩 Generating ${OUTPUT_FILE} from ${APPS_DIR}/*/t-apps.yml..."

# Initialize empty JSON array
echo "[]" > "$OUTPUT_FILE"

# Loop over all t-apps.yml files
for app_file in ${APPS_DIR}/*/t-apps.yml; do
  if [ -f "$app_file" ]; then
    app_dir=$(basename "$(dirname "$app_file")")

    # Extract YAML content as JSON
    app_json=$(yq -o=json '.' "$app_file")

    # Add gallery URLs dynamically
    gallery_json=$(yq -o=json '.galery' "$app_file" | jq -r --arg repo "$GITHUB_REPO" --arg branch "$BRANCH" --arg app "$app_dir" '
      map("https://cdn.jsdelivr.net/gh/\($repo)@\($branch)/apps/\($app)/" + .)
    ')

    # Merge fields (replace gallery field with full URLs)
    app_json=$(echo "$app_json" | jq --argjson gallery "$gallery_json" '.gallery = $gallery')

    # Append to main JSON
    tmp=$(mktemp)
    jq ". + [${app_json}]" "$OUTPUT_FILE" > "$tmp" && mv "$tmp" "$OUTPUT_FILE"
  fi
done

echo "✅ apps.json successfully generated!"

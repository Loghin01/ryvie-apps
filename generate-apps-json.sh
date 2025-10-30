#!/bin/bash
# ----------------------------------------------------------
# Script: generate_apps_json.sh
# Description: Generate apps.json from t-apps.yml metadata,
#              with automatic gallery URL generation.
#              Adapted for GitHub Actions (non-interactive).
# ----------------------------------------------------------

set -e

# ------------------------------
# Check dependencies (CI-friendly)
# ------------------------------
command -v jq >/dev/null 2>&1 || { echo "❌ jq is not installed. Exiting."; exit 1; }
command -v yq >/dev/null 2>&1 || { echo "❌ yq is not installed. Exiting."; exit 1; }

# ------------------------------
# Variables principales
# ------------------------------
APPS_DIR="apps"
OUTPUT_FILE="apps.json"
GITHUB_REPO="ryvie/ryvie-apps"
BRANCH="main"

echo "🧩 Generating ${OUTPUT_FILE} from ${APPS_DIR}/*/ryvie-apps.yml..."

# Initialize empty JSON array
echo "[]" > "$OUTPUT_FILE"

# Loop over all t-apps.yml files
for app_file in ${APPS_DIR}/*/ryvie-apps.yml; do
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

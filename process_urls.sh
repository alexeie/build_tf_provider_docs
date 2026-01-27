#!/bin/bash

# Configuration with defaults
OWNER=${PROVIDER_OWNER:-snowflakedb}
REPO=${PROVIDER_REPO:-terraform-provider-snowflake}
BRANCH=${PROVIDER_BRANCH:-main}
PROVIDER=${PROVIDER_CAP:-snowflake}
URLS_FILE=${URLS_FILE:-urls.txt}

# Build auth header if GITHUB_TOKEN is set
CURL_AUTH=()
if [ -n "$GITHUB_TOKEN" ]; then
    CURL_AUTH=(-H "Authorization: token $GITHUB_TOKEN")
fi

# URL for changelog
CHANGELOG_URL="https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}/CHANGELOG.md"

# Get the version from CHANGELOG.md
version=$(curl -s "${CURL_AUTH[@]}" "$CHANGELOG_URL" | grep -m 1 '## \[' | awk -F'[][]' '{print $2}' | tr -d '\r')

# Fallback version if not found
if [ -z "$version" ]; then
    version="latest"
fi

output_file="${PROVIDER}_${version}.md"

# Start with the main title
echo "# ${PROVIDER} Terraform Provider Documentation v${version}" > "$output_file"
echo "" >> "$output_file"
echo "## All Resources" >> "$output_file"

# Create a global TOC
while IFS= read -r url; do
    filename=$(basename "$url" .md)
    resource_name="${PROVIDER}_${filename}"
    anchor_name=$(echo "$resource_name" | tr '_' '-')
    echo "* [${resource_name}](#${anchor_name})" >> "$output_file"
done < "$URLS_FILE"
echo "" >> "$output_file"

# Download all doc files in parallel
DOWNLOAD_DIR=$(mktemp -d)
if [ -n "$GITHUB_TOKEN" ]; then
  xargs -P 10 -I {} sh -c 'curl -sf -H "Authorization: token $GITHUB_TOKEN" "$1" -o "'"$DOWNLOAD_DIR"'/$(basename "$1")"' _ {} < "$URLS_FILE"
else
  xargs -P 10 -I {} sh -c 'curl -sf "$1" -o "'"$DOWNLOAD_DIR"'/$(basename "$1")"' _ {} < "$URLS_FILE"
fi

# Process each downloaded file
while IFS= read -r url; do
  filename=$(basename "$url")
  filepath="${DOWNLOAD_DIR}/${filename}"

  if [ ! -s "$filepath" ]; then
    echo "Warning: Failed to fetch ${url}" >&2
    continue
  fi

  content=$(cat "$filepath")
  resource_name="${PROVIDER}_${filename%.md}"

  # Add resource heading
  echo "" >> "$output_file"
  echo "## ${resource_name}" >> "$output_file"

  # Generate TOC for the current resource
  echo "### Table of Contents" >> "$output_file"
  printf "%s" "$content" | grep '^## ' | sed 's/^## //' | while IFS= read -r heading; do
    # Create a markdown-friendly anchor link
    anchor=$(echo "$heading" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 -]//g' | tr ' ' '-' | sed 's/--*/-/g')
    echo "* [${heading}](#${anchor})" >> "$output_file"
  done
  echo "" >> "$output_file"

  # Append the rest of the content, skipping the main title
  printf "%s" "$content" | sed -n '/^# /,$p' | sed '1d' >> "$output_file"
  echo "" >> "$output_file"
done < "$URLS_FILE"

# Clean up downloaded files
rm -rf "$DOWNLOAD_DIR"

echo "Documentation generated in ${output_file}"

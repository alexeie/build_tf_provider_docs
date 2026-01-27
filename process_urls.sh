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

# Download all doc files in parallel
DOWNLOAD_DIR=$(mktemp -d)
if [ -n "$GITHUB_TOKEN" ]; then
  xargs -P 10 -I {} sh -c 'curl -sf -H "Authorization: token $GITHUB_TOKEN" "$1" -o "'"$DOWNLOAD_DIR"'/$(basename "$1")"' _ {} < "$URLS_FILE"
else
  xargs -P 10 -I {} sh -c 'curl -sf "$1" -o "'"$DOWNLOAD_DIR"'/$(basename "$1")"' _ {} < "$URLS_FILE"
fi

# Classify URLs into 4 categories based on type and preview status
resources_stable=$(mktemp)
resources_preview=$(mktemp)
datasources_stable=$(mktemp)
datasources_preview=$(mktemp)

while IFS= read -r url; do
  filename=$(basename "$url")
  filepath="${DOWNLOAD_DIR}/${filename}"
  [ ! -s "$filepath" ] && continue

  is_preview=false
  if grep -q 'subcategory: "Preview"' "$filepath" 2>/dev/null; then
    is_preview=true
  fi

  if echo "$url" | grep -q '/docs/data-sources/'; then
    if $is_preview; then
      echo "$url" >> "$datasources_preview"
    else
      echo "$url" >> "$datasources_stable"
    fi
  else
    if $is_preview; then
      echo "$url" >> "$resources_preview"
    else
      echo "$url" >> "$resources_stable"
    fi
  fi
done < "$URLS_FILE"

# Helper: generate TOC entries for a list of URLs
generate_toc_entries() {
  local list_file="$1"
  local type_label="$2"
  [ ! -s "$list_file" ] && return
  while IFS= read -r url; do
    filename=$(basename "$url" .md)
    resource_name="${PROVIDER}_${filename}"
    resource_label="${resource_name} (${type_label})"
    anchor_name=$(echo "$resource_label" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 _-]//g' | tr ' ' '-')
    echo "* [${resource_label}](#${anchor_name})" >> "$output_file"
  done < "$list_file"
}

# Generate global TOC with 4 sections
echo "## All Resources" >> "$output_file"
echo "" >> "$output_file"

if [ -s "$resources_stable" ]; then
  echo "### Resources" >> "$output_file"
  generate_toc_entries "$resources_stable" "resource"
  echo "" >> "$output_file"
fi

if [ -s "$resources_preview" ]; then
  echo "### Resources (Preview)" >> "$output_file"
  generate_toc_entries "$resources_preview" "resource, preview"
  echo "" >> "$output_file"
fi

if [ -s "$datasources_stable" ]; then
  echo "### Data Sources" >> "$output_file"
  generate_toc_entries "$datasources_stable" "data source"
  echo "" >> "$output_file"
fi

if [ -s "$datasources_preview" ]; then
  echo "### Data Sources (Preview)" >> "$output_file"
  generate_toc_entries "$datasources_preview" "data source, preview"
  echo "" >> "$output_file"
fi

# Helper: process and append content for a list of URLs
process_url_list() {
  local list_file="$1"
  local type_label="$2"
  [ ! -s "$list_file" ] && return
  while IFS= read -r url; do
    filename=$(basename "$url")
    filepath="${DOWNLOAD_DIR}/${filename}"

    if [ ! -s "$filepath" ]; then
      echo "Warning: Failed to fetch ${url}" >&2
      continue
    fi

    content=$(cat "$filepath")
    resource_name="${PROVIDER}_${filename%.md}"
    resource_label="${resource_name} (${type_label})"

    # Add resource heading
    echo "" >> "$output_file"
    echo "## ${resource_label}" >> "$output_file"

    # Generate TOC for the current resource
    echo "### Table of Contents" >> "$output_file"
    printf "%s" "$content" | grep '^## ' | sed 's/^## //' | while IFS= read -r heading; do
      anchor=$(echo "$heading" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 -]//g' | tr ' ' '-' | sed 's/--*/-/g')
      echo "* [${heading}](#${anchor})" >> "$output_file"
    done
    echo "" >> "$output_file"

    # Append the rest of the content, skipping the main title
    printf "%s" "$content" | sed -n '/^# /,$p' | sed '1d' >> "$output_file"
    echo "" >> "$output_file"
  done < "$list_file"
}

# Process content in same order as TOC
process_url_list "$resources_stable" "resource"
process_url_list "$resources_preview" "resource, preview"
process_url_list "$datasources_stable" "data source"
process_url_list "$datasources_preview" "data source, preview"

# Clean up category files
rm -f "$resources_stable" "$resources_preview" "$datasources_stable" "$datasources_preview"

# Clean up downloaded files
rm -rf "$DOWNLOAD_DIR"

echo "Documentation generated in ${output_file}"

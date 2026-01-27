#!/bin/bash

# Configuration with defaults
OWNER=${PROVIDER_OWNER:-snowflakedb}
REPO=${PROVIDER_REPO:-terraform-provider-snowflake}
BRANCH=${PROVIDER_BRANCH:-main}
PROVIDER=${PROVIDER_CAP:-snowflake}
URLS_FILE=${URLS_FILE:-urls.txt}

# URL for changelog
CHANGELOG_URL="https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}/CHANGELOG.md"

# Get the version from CHANGELOG.md
version=$(curl -s "$CHANGELOG_URL" | grep -m 1 '## \[' | awk -F'[][]' '{print $2}' | tr -d '\r')

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

# Process each URL
while IFS= read -r url; do
  content=$(curl -sf "$url")
  if [ $? -ne 0 ]; then
    echo "Warning: Failed to fetch ${url}" >&2
    continue
  fi

  # Extract resource name for heading
  filename=$(basename "$url" .md)
  resource_name="${PROVIDER}_${filename}"

  # Add resource heading
  echo "" >> "$output_file"
  echo "## ${resource_name}" >> "$output_file"

  # Generate TOC for the current resource
  echo "### Table of Contents" >> "$output_file"
  printf "%s" "$content" | grep '^## ' | sed 's/^## //' | while IFS= read -r heading; do
    # Create a markdown-friendly anchor link
    anchor=$(echo "$heading" | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]' | tr ' ' '-')
    echo "* [${heading}](#${anchor})" >> "$output_file"
  done
  echo "" >> "$output_file"

  # Append the rest of the content, skipping the main title
  printf "%s" "$content" | sed -n '/^# /,$p' | sed '1d' >> "$output_file"
  echo "" >> "$output_file"
done < "$URLS_FILE"

echo "Documentation generated in ${output_file}"

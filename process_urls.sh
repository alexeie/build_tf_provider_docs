#!/bin/bash

# Get the version from CHANGELOG.md
version=$(curl -s "https://raw.githubusercontent.com/snowflakedb/terraform-provider-snowflake/main/CHANGELOG.md" | grep -m 1 '## \[' | awk -F'[][]' '{print $2}')
output_file="snowflake_${version}.md"

# Start with the main title
echo "# Snowflake Terraform Provider Documentation v${version}" > "$output_file"
echo "" >> "$output_file"
echo "## All Resources" >> "$output_file"
echo "## Table of Contents" >> "$output_file"

# Create a global TOC
while IFS= read -r url; do
    filename=$(basename "$url" .md)
    resource_name="snowflake_${filename}"
    anchor_name=$(echo "$resource_name" | tr '_' '-')
    echo "* [${resource_name}](#${anchor_name})" >> "$output_file"
done < urls.txt
echo "" >> "$output_file"

# Process each URL
while IFS= read -r url; do
  content=$(curl -s "$url")

  # Extract resource name for heading
  filename=$(basename "$url" .md)
  resource_name="snowflake_${filename}"

  # Add resource heading
  echo "" >> "$output_file"
  echo "## ${resource_name}" >> "$output_file"

  # Generate TOC for the current resource
  echo "## Table of Contents" >> "$output_file"
  printf "%s" "$content" | grep '^## ' | sed 's/^## //' | while IFS= read -r heading; do
    # Create a markdown-friendly anchor link
    anchor=$(echo "$heading" | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]' | tr ' ' '-')
    echo "* [${heading}](#${anchor})" >> "$output_file"
  done
  echo "" >> "$output_file"

  # Append the rest of the content, skipping the main title
  printf "%s" "$content" | sed -n '/^# /,$p' | sed '1d' >> "$output_file"
  echo "" >> "$output_file"
done < urls.txt

echo "Documentation generated in ${output_file}"

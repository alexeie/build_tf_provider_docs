#!/bin/bash

# Initialize the markdown file with a main title
echo "# Snowflake Terraform Provider Documentation" > snowflake_docs.md
echo "" >> snowflake_docs.md

# Separate sections for data sources and resources
echo "## Data Sources" >> snowflake_docs.md
echo "" >> snowflake_docs.md

# Process data source files first
grep 'data-sources' urls.txt | while read -r url; do
    # Extract filename, remove extension, and format as a title
    filename=$(basename "$url")
    title=$(echo "$filename" | sed 's/\.md$//' | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')

    echo "### $title" >> snowflake_docs.md
    curl -s "$url" >> snowflake_docs.md
    echo "" >> snowflake_docs.md
    echo "" >> snowflake_docs.md
done

echo "## Resources" >> snowflake_docs.md
echo "" >> snowflake_docs.md

# Process resource files
grep 'resources' urls.txt | while read -r url; do
    # Extract filename, remove extension, and format as a title
    filename=$(basename "$url")
    title=$(echo "$filename" | sed 's/\.md$//' | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')

    echo "### $title" >> snowflake_docs.md
    curl -s "$url" >> snowflake_docs.md
    echo "" >> snowflake_docs.md
    echo "" >> snowflake_docs.md
done

# Snowflake Terraform Provider Documentation Builder

This utility builds a single-file Markdown documentation for the Snowflake Terraform Provider. It fetches the documentation from the official `snowflakedb/terraform-provider-snowflake` GitHub repository and consolidates it into one file. This is useful for providing a comprehensive, searchable reference for local use.

## Prerequisites

This tool relies on a few common command-line utilities that are typically available in a standard Unix-like environment (such as Linux, macOS, or Windows Subsystem for Linux).

*   `curl`: Used to fetch data from URLs.
*   `grep`, `awk`, `sed`, `basename`: Standard text-processing utilities.
*   `python`: Used to run the script that generates the list of documentation URLs. No external libraries are needed.

## Usage

Follow these steps to generate the documentation from scratch.

### Step 1: Fetch the Repository File Structure

The first step is to get the file structure of the Snowflake Terraform Provider's documentation directory. This is done by querying the GitHub API and saving the output to a file named `github_tree.json`.

Run the following command in your terminal:

```sh
curl -s "https://api.github.com/repos/snowflakedb/terraform-provider-snowflake/git/trees/main?recursive=1" -o github_tree.json
```

This will create the `github_tree.json` file in your current directory.

### Step 2: Generate the List of Documentation URLs

Next, run the provided Python script to process `github_tree.json`. This script extracts the paths to the relevant documentation files, constructs the full URLs, and saves them into a file named `urls.txt`.

```sh
python scrape.py
```

This will create the `urls.txt` file.

### Step 3: Generate the Documentation File

Finally, run the shell script to fetch the content of each URL and build the final documentation file. The script will automatically determine the latest version of the provider and include it in the output filename (e.g., `snowflake_2.5.0.md`).

```sh
bash process_urls.sh
```

Upon completion, you will find a new markdown file in your directory with the consolidated documentation. The script will print the name of the generated file, for example: `Documentation generated in snowflake_2.5.0.md`.

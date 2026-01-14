# Terraform Provider Documentation Builder

This utility builds a single-file Markdown documentation for a specified Terraform Provider GitHub repository. It fetches the documentation from the given repository and consolidates it into one file. This is useful for providing a comprehensive, searchable reference for local use.

## Prerequisites

This tool relies on a few common command-line utilities that are typically available in a standard Unix-like environment (such as Linux, macOS, or Windows Subsystem for Linux).

*   `curl`: Used to fetch data from URLs.
*   `grep`, `awk`, `sed`, `basename`: Standard text-processing utilities.
*   `python`: Used to run the main script. No external libraries are needed.

## Usage

To generate the documentation, run the `scrape.py` script with the GitHub repository URL of the Terraform provider.

### Using Pip (Standard Python)

1.  **Set up a virtual environment (Optional but recommended):**
    ```sh
    python3 -m venv venv
    source venv/bin/activate  # On macOS/Linux
    # venv\Scripts\activate   # On Windows
    ```

2.  **Install dependencies:**
    ```sh
    pip install -r requirements.txt
    ```

3.  **Run the script:**
    ```sh
    python scrape.py <repo_url>
    ```

### Using uv

[uv](https://docs.astral.sh/uv/) is a fast Python package installer and runner.

1.  **Run directly:**
    ```sh
    uv run scrape.py <repo_url>
    ```

### Examples

**Snowflake Provider:**
```sh
python scrape.py https://github.com/snowflakedb/terraform-provider-snowflake
```
This will generate a file like `snowflake_2.5.0.md` (version depends on the latest tag in CHANGELOG.md).

**dbt Cloud Provider:**
```sh
python scrape.py https://github.com/dbt-labs/terraform-provider-dbtcloud
```
This will generate a file like `dbtcloud_0.2.0.md`.

## How it works

1.  **Repo Analysis**: The script parses the provided URL to identify the owner and repository name, and determines the default branch (e.g., `main` or `master`).
2.  **Fetch File Structure**: It uses the GitHub API to fetch the file tree of the repository and saves it to `github_tree.json`.
3.  **Generate URL List**: It parses the tree to find markdown files in `docs/resources/` and `docs/data-sources/`, constructing raw content URLs, and saves them to `urls.txt`.
4.  **Build Documentation**: It runs `process_urls.sh`, which:
    *   Determines the version from `CHANGELOG.md`.
    *   Downloads each markdown file.
    *   Adds a table of contents.
    *   Concatenates everything into a single Markdown file.

import sys
import json
import subprocess
import re
import os

def get_repo_info(repo_url):
    """Parses the repository URL to extract owner and repo name."""
    # Matches https://github.com/owner/repo or github.com/owner/repo
    match = re.search(r'github\.com/([^/]+)/([^/]+?)(?:\.git)?$', repo_url)
    if not match:
        raise ValueError(f"Invalid GitHub URL: {repo_url}")
    owner, repo = match.groups()
    return owner, repo

def get_default_branch(owner, repo):
    """Fetches the default branch of the repository."""
    api_url = f"https://api.github.com/repos/{owner}/{repo}"
    try:
        # Using curl to fetch repo info
        result = subprocess.check_output(['curl', '-s', api_url], text=True)
        data = json.loads(result)
        return data.get('default_branch', 'main')
    except Exception as e:
        print(f"Warning: Could not determine default branch. Defaulting to 'main'. Error: {e}")
        return 'main'

def fetch_tree(owner, repo, branch):
    """Fetches the git tree structure recursively."""
    url = f"https://api.github.com/repos/{owner}/{repo}/git/trees/{branch}?recursive=1"
    print(f"Fetching file structure from {url}...")
    try:
        subprocess.check_call(['curl', '-s', url, '-o', 'github_tree.json'])
    except subprocess.CalledProcessError as e:
        print(f"Error fetching tree: {e}")
        sys.exit(1)

def create_url_list(owner, repo, branch):
    """Parses github_tree.json and creates urls.txt with raw file URLs."""
    try:
        with open('github_tree.json', 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print("Error: github_tree.json not found.")
        sys.exit(1)
    except json.JSONDecodeError:
        print("Error: github_tree.json is not valid JSON. Ensure the repo exists and is public.")
        sys.exit(1)

    urls = []
    base_url = f"https://raw.githubusercontent.com/{owner}/{repo}/{branch}"

    # Check if 'tree' key exists (it might not if API rate limit exceeded or repo not found)
    if 'tree' not in data:
        print("Error: 'tree' not found in response. API response might be an error:")
        print(json.dumps(data, indent=2))
        sys.exit(1)

    for item in data.get('tree', []):
        path = item.get('path', '')
        # Filter for documentation files
        if (path.startswith('docs/resources/') or path.startswith('docs/data-sources/')) and path.endswith('.md'):
            urls.append(f"{base_url}/{path}")

    with open('urls.txt', 'w') as f:
        for url in sorted(urls):
            f.write(f"{url}\n")

    print(f"Generated urls.txt with {len(urls)} URLs.")

def main():
    if len(sys.argv) < 2:
        print("Usage: python scrape.py <repo_url>")
        sys.exit(1)

    repo_url = sys.argv[1]

    try:
        owner, repo = get_repo_info(repo_url)
    except ValueError as e:
        print(e)
        sys.exit(1)

    print(f"Targeting repo: {owner}/{repo}")

    branch = get_default_branch(owner, repo)
    print(f"Using branch: {branch}")

    fetch_tree(owner, repo, branch)
    create_url_list(owner, repo, branch)

    # Determine provider name for naming conventions
    # e.g. terraform-provider-snowflake -> snowflake
    # e.g. terraform-provider-dbtcloud -> dbtcloud
    if repo.startswith('terraform-provider-'):
        provider = repo.replace('terraform-provider-', '')
    else:
        provider = repo

    print(f"Detected provider name: {provider}")
    print("Running process_urls.sh...")

    # Prepare environment variables for the bash script
    env = os.environ.copy()
    env['PROVIDER_OWNER'] = owner
    env['PROVIDER_REPO'] = repo
    env['PROVIDER_BRANCH'] = branch
    env['PROVIDER_NAME'] = provider
    env["PROVIDER_CAP"] = provider.capitalize()

    try:
        subprocess.check_call(['bash', 'process_urls.sh'], env=env)
    except subprocess.CalledProcessError as e:
        print(f"Error running process_urls.sh: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()

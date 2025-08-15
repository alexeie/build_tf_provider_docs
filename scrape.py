import json
import os

def create_url_list():
    with open('github_tree.json', 'r') as f:
        data = json.load(f)

    urls = []
    for item in data.get('tree', []):
        path = item.get('path', '')
        if (path.startswith('docs/resources/') or path.startswith('docs/data-sources/')) and path.endswith('.md'):
            urls.append(f"https://raw.githubusercontent.com/snowflakedb/terraform-provider-snowflake/main/{path}")

    with open('urls.txt', 'w') as f:
        for url in sorted(urls):
            f.write(f"{url}\n")

if __name__ == '__main__':
    create_url_list()

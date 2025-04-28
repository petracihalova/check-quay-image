# 🔍 check-quay-image

This action checks if a Quay image (tagged with the commit SHA) exists after a PR is merged.

It's useful when:

* Image builds (e.g. by Konflux) are not triggered automatically.
* You want to see if the image is missing or delayed.
* Your CI/CD depends on the image being ready.
It helps you catch problems early, before they break later steps.

## Features

- Works with public or private Quay.io repositories
- Polling logic with initial delay and retry intervals
- Fails the workflow if the image is not found

## Inputs

| Name               | Required | Default | Description |
|--------------------|----------|---------|-------------|
| `quay_repo`        | ✅       |         | `namespace/repo` format |
| `commit_sha`       | ✅       |         | Commit SHA to match tag |
| `delay_minutes`    | ❌       | 10      | Initial delay before first check |
| `retries`          | ❌       | 20      | Number of retry attempts |
| `interval_minutes` | ❌       | 1       | Time between retries |
| `slack_webhook_url`| ❌       |         | Slack webhook URL for notification on failure |

<!-- | `quay_private`     | ❌       | false   | Set to `"true"` if repo is private |
| `quay_token`       | ❌       |         | Quay API token (used only if private) | -->

## Example Usage
for image in repo https://quay.io/repository/redhat-services-prod/hcc-accessmanagement-tenant/insights-rbac 

```yaml
name: Check Quay Image

on:
  push:
    branches:
      - main

jobs:
  check-image:
    runs-on: ubuntu-latest
    steps:
      - name: Wait for Quay image
        uses: petracihalova/check-quay-image@v1
        with:
          quay_repo: redhat-services-prod/hcc-accessmanagement-tenant/insights-rbac
          commit_sha: ${{ github.sha }}

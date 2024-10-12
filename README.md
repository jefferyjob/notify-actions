# Notification Action
A GitHub Action to send notifications to various messaging platforms (e.g., Feishu, DingTalk, Work WeChat, ShowDoc) based on deployment status.

## Features

- Supports multiple notification types.
- Allows sending messages in various formats (text, markdown, card).
- Can be used to notify about deployment statuses, making it easy to integrate into CI/CD pipelines.
- Customizable to fit different repository and workflow requirements.

## Inputs
| Variable name | Required | Description |
| ------------ | -------- | --------------------- |
| NOTICE_TYPE | Yes | Notification type (such as `feishu`, `dingtalk`, `workWechat`, `showDoc`). |
| MSG_TYPE | Yes | Message format (such as `text`, `markdown`, `card`). |
| STATUS | Yes | Deployment status, `1` indicates success, `0` indicates failure, used to identify whether this deployment is successful. |
| WEBHOOK_URL | Yes | Webhook address of notification service, used to send deployment notifications to platforms such as Feishu and DingTalk. |
| REPO | Yes | Repository name, which identifies the name of the current project, usually used to distinguish different applications or services (such as: `organizations/repo`). |
| REPO_URL | Yes | The URL of the repository, pointing to the source code repository of the project, for easy viewing of the code base (e.g., `https://example.com/organizations/repo`). |
| WORKFLOW_URL | Yes | The URL of the deployment pipeline, providing detailed information about the execution process of this deployment (e.g., `https://ci.example.com/organizations/repo/workflow/1`). |
| BRANCH | No | Deployment branch, specifying which branch to deploy the code from. If not specified, the default branch (e.g., `main`) is used. |
| COMMIT_USER | No | The author who submitted the code, used to record and display the information of the person who triggered this deployment. |
| COMMIT_SHA | No | The Git hash value of the submission, used to uniquely identify the specific submission version, for easy tracking and rollback (e.g., `a1b2c3d`). |
| COMMIT_MESSAGE | No | Commit message, recording the comments when this code is submitted, to facilitate understanding of the purpose and background of the code change. |

## Example Workflow

Here's an example of how to use this action in your GitHub workflow:

```yaml
name: Deploy Notification

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Determine Branch
        run: |
          if [ "${{ github.event_name }}" == "pull_request" ]; then
            echo "BRANCH=${{ github.head_ref }}" >> $GITHUB_ENV
          else
            echo "BRANCH=${{ github.ref_name }}" >> $GITHUB_ENV
          fi

      - name: Send Notification
        uses: ./ # Use local action
        with:
          NOTICE_TYPE: 'feishu'
          MSG_TYPE: 'text'
          STATUS: '1'
          WEBHOOK_URL: ${{ secrets.FEISHU_WEBHOOK }}
          REPO: ${{ github.repository }}
          REPO_URL: ${{ github.server_url }}/${{ github.repository }}
          WORKFLOW_URL: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
          BRANCH: ${{ env.BRANCH }}
          COMMIT_USER: ${{ github.event.head_commit.author.name }}
          COMMIT_SHA: ${{ github.sha }}
          COMMIT_MESSAGE: ${{ github.event.head_commit.message }}
```

## License
This project is licensed under the [MIT License](LICENSE).

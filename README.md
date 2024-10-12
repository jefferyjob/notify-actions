# Notification Action
English | [简体中文](README.cn.md)

## Introduction
A GitHub Action to send notifications to various messaging platforms (e.g., Feishu, DingTalk, Work WeChat, ShowDoc) based on deployment status.

## Features
- Supports multiple notification types.
- Allows sending messages in various formats (text, markdown, card).
- Can be used to notify about deployment statuses, making it easy to integrate into CI/CD pipelines.
- Customizable to fit different repository and workflow requirements.

## Example Workflow

```yaml
- name: Send Notification
  uses: jefferyjob@notice-actions@v1
  with:
    NOTICE_TYPE: ''
    MSG_TYPE: ''
    STATUS: ''
    WEBHOOK_URL: ''
    REPO: ''
    REPO_URL: ''
    WORKFLOW_URL: ''
    BRANCH: ''
    COMMIT_USER: ''
    COMMIT_SHA: ''
    COMMIT_MESSAGE: ''
```

## Parameter configuration
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


## License
This project is licensed under the [MIT License](LICENSE).

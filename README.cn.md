# Notification Action
[English](README.md) | 简体中文

## 介绍
GitHub 操作可根据部署状态向各种消息平台（例如，飞书、钉钉、企业微信、ShowDoc）发送通知。

## 功能
- 支持多种通知类型。
- 允许以各种格式（文本、markdown、卡片）发送消息。
- 可用于通知部署状态，使其易于集成到 CI/CD 管道中。
- 可定制以适应不同的存储库和工作流要求。

## 示例工作流程

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

## 参数配置

| 变量名称 | 必需 | 说明 |
| ------------ | -------- | --------------------- |
| NOTICE_TYPE | 是 |通知类型（如 `feishu`、`dingtalk`、`workWechat`、`showDoc`）。|
| MSG_TYPE | 是 | 消息格式（如 `text`、`markdown`、`card`）。|
| STATUS     | 是    | 部署状态，`1` 表示成功，`0` 表示失败，用于标识本次部署是否成功。                                        |
| WEBHOOK_URL | 是    | 通知服务的 Webhook 地址，用于向如飞书、钉钉等平台发送部署通知。                                        |
| REPO       | 是    | 仓库名称，标识当前项目的名称，通常用于区分不同的应用或服务（如：`organizations/repo`）。                      |
| REPO_URL   | 是    | 仓库的 URL 地址，指向项目的源码仓库位置，便于查看代码库（如：`https://example.com/organizations/repo`）。 |
| WORKFLOW_URL | 是    | 部署流水线的 URL 地址，提供本次部署执行流程的详细信息（如：`https://ci.example.com/organizations/repo/workflow/1`）。      |
| BRANCH     | 否    | 部署分支，指定从哪个分支进行代码部署，若不指定则使用默认分支（如：`main`）。                                   |
| COMMIT_USER | 否    | 提交代码的作者，用于记录和展示触发本次部署的人员信息。                                                 |
| COMMIT_SHA | 否    | 提交的 Git 哈希值，用于唯一标识具体的提交版本，便于追踪和回滚（如：`a1b2c3d`）。                             |
| COMMIT_MESSAGE | 否    | 提交信息，记录本次代码提交时的备注内容，便于理解代码更改的目的和背景。                                         |


## 许可证
This project is licensed under the [MIT License](LICENSE).
#!/bin/bash
set -e

# 被测试脚本
SCRIPT="./notify.sh"

# 测试前赋予权限
# chmod 755 notify.sh notify_test.sh

##############################################################################
# 基础环境变量
##############################################################################
export STATUS=1
# export WEBHOOK_URL="https://xxxx.com" # 保密信息（从本机环境变量获取）
export REPO="jefferyjob/notify-actions"
export REPO_URL="https://github.com/jefferyjob/notify-actions"
export BRANCH="main"
export COMMIT_USER="make"
export COMMIT_SHA="e981969435cbe9e6ec31be2ea5b7477306d3d83b"
export COMMIT_MESSAGE="Fixed parameter issues"
export WORKFLOW_URL="https://github.com/jefferyjob/notify-actions/actions"


##############################################################################
# 测试飞书
export WEBHOOK_URL="${FeishuWebhookUrl}"
##############################################################################
#$SCRIPT feishu text
#$SCRIPT feishu markdown
#$SCRIPT feishu card


##############################################################################
# 测试钉钉
export WEBHOOK_URL="${DingTalkWebhookUrl}"
##############################################################################
#$SCRIPT dingtalk text
#$SCRIPT dingtalk markdown


##############################################################################
# 测试企业微信
export WEBHOOK_URL="${WorkWechatWebhookUrl}"
##############################################################################
#$SCRIPT workWechat text
#$SCRIPT workWechat markdown


##############################################################################
# 测试showDoc
export WEBHOOK_URL="${ShowDocWebhookUrl}"
##############################################################################
#$SCRIPT showDoc text
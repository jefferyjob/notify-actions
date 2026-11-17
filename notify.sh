#!/bin/bash
set -e

# 传入参数转小写
NOTICE_TYPE=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
MSG_TYPE=$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')

# 通知时间使用的时区（可通过 TIMEZONE 环境变量覆盖）
TZ_NAME="${TIMEZONE:-Asia/Shanghai}"

now() {
  TZ="$TZ_NAME" date +"%Y-%m-%d %H:%M:%S"
}

# 帮助信息
print_usage() {
  echo "Usage: $0 <NOTICE_TYPE> <MSG_TYPE>"
  echo ""
  echo "Parameters:"
  echo "  <NOTICE_TYPE>   The platform to send the notification."
  echo "  <MSG_TYPE>      The format of the notification message."
  echo ""
  echo "Valid values for <NOTICE_TYPE> are:"
  echo "  feishu       Use Feishu to send the notification."
  echo "  dingtalk     Use DingTalk to send the notification."
  echo "  workWechat   Use WeChat Work to send the notification."
  echo "  showDoc      Use ShowDoc to send the notification."
  echo ""
  echo "Valid values for <MSG_TYPE> are:"
  echo "  text        Send a plain text notification."
  echo "  markdown    Send a Markdown formatted notification."
  echo "  card        Send a card-style notification (feishu only)."
  echo ""
}

if [[ "${1:-}" == "--help" ]]; then
  print_usage
  exit 0
fi

# WEBHOOK_URL 中包含访问凭据，日志中仅显示协议与域名部分
mask_webhook_url() {
  local url="$WEBHOOK_URL"
  if [[ "$url" =~ ^(https?://[^/?#]+) ]]; then
    printf '%s/******\n' "${BASH_REMATCH[1]}"
  else
    printf '%s\n' "******"
  fi
}

print_env() {
  echo "--------------------------------------------------------------------------"
  echo "  Shell Notification < Initialization Parameters >"
  echo "--------------------------------------------------------------------------"
  echo "  NOTICE_TYPE: $NOTICE_TYPE"
  echo "  MSG_TYPE: $MSG_TYPE"
  echo "--------------------------------------------------------------------------"
  echo "  STATUS: $STATUS"
  echo "  WEBHOOK_URL: $(mask_webhook_url)"
  echo "  REPO: $REPO"
  echo "  REPO_URL: $REPO_URL"
  echo "  BRANCH: $BRANCH"
  echo "  COMMIT_USER: $COMMIT_USER"
  echo "  COMMIT_SHA: $COMMIT_SHA"
  echo "  COMMIT_MESSAGE: $COMMIT_MESSAGE"
  echo "  WORKFLOW_URL: $WORKFLOW_URL"
  echo "--------------------------------------------------------------------------"
}

print_env

######################################################################
# Shell 脚本运行参数验证
######################################################################
# 检查是否提供了足够的参数
if [ "$#" -lt 2 ]; then
  print_usage
  exit 1
fi

# 检查服务器授权方式
case "$NOTICE_TYPE" in
  feishu|dingtalk|workwechat|showdoc) ;;
  *)
    echo "Error: NOTICE_TYPE parameter validation error."
    exit 1
    ;;
esac

# 检查执行动作
case "$MSG_TYPE" in
  text|markdown|card) ;;
  *)
    echo "Error: MSG_TYPE parameter validation error."
    exit 1
    ;;
esac

# card 仅飞书支持
if [[ "$MSG_TYPE" == "card" && "$NOTICE_TYPE" != "feishu" ]]; then
  echo "Error: MSG_TYPE 'card' is only supported by feishu."
  exit 1
fi

check_param() {
  local param_name="$1"
  local param_value="$2"
  if [[ -z "$param_value" ]]; then
    echo "Error: $param_name The environment variable parameter cannot be empty"
    exit 1
  fi
}

# 环境变量参数验证
check_param "STATUS" "$STATUS"
check_param "WEBHOOK_URL" "$WEBHOOK_URL"
check_param "REPO" "$REPO"
check_param "REPO_URL" "$REPO_URL"
check_param "WORKFLOW_URL" "$WORKFLOW_URL"

if [[ "$STATUS" == "1" || "$STATUS" == "true" ]]; then
  STATUS_MSG="成功"
  CONTENT_TITLE="部署成功通知"
  COLOR="green"
else
  STATUS_MSG="失败"
  CONTENT_TITLE="部署失败通知"
  COLOR="red"
fi

# sha 信息获取前面7位
COMMIT_SHA=$(printf '%s' "$COMMIT_SHA" | cut -c 1-7)

######################################################################
# HTTP 请求
######################################################################
# 统一的 POST 出口：
# - --fail          HTTP 4xx/5xx 时视为失败
# - --connect-timeout/--max-time  避免网络挂起阻塞流水线
# - FAIL_ON_ERROR=true 时通知失败将使 Action 失败，默认仅告警继续
http_post() {
  local response
  if ! response=$(curl --fail --silent --show-error --connect-timeout 10 --max-time 30 "$@" "$WEBHOOK_URL" 2>&1); then
    echo "Error: notification request failed:"
    echo "$response"
    if [[ "${FAIL_ON_ERROR:-false}" == "true" ]]; then
      exit 1
    fi
    echo "Notice: FAIL_ON_ERROR is disabled, the workflow will continue."
    return 0
  fi
  printf '%s\n' "$response"
}

# 使用 jq 构造 JSON，所有动态字段经 --arg 传入，避免拼接转义问题
json_payload() {
  jq -n "$@"
}

######################################################################
# 文本通知
######################################################################
TRIGGER_TIME="$(now)"
CONTENT="$CONTENT_TITLE

仓库: $REPO
分支: $BRANCH
作者: $COMMIT_USER
哈希: $COMMIT_SHA
信息: $COMMIT_MESSAGE
时间: $TRIGGER_TIME
状态: $STATUS_MSG
详情: $WORKFLOW_URL"

notice_feishu_text() {
  local payload
  payload=$(json_payload --arg text "$CONTENT" '{
    "msg_type": "text",
    "content": {
      "text": $text
    }
  }')
  http_post -H 'Content-Type: application/json' -d "$payload"
}

notice_workWechat_text() {
  local payload
  payload=$(json_payload --arg text "$CONTENT" '{
    "msgtype": "text",
    "text": {
      "content": $text
    }
  }')
  http_post -H 'Content-Type: application/json' -d "$payload"
}

notice_dingtalk_text() {
  local payload
  payload=$(json_payload --arg text "$CONTENT" '{
    "msgtype": "text",
    "text": {
      "content": $text
    }
  }')
  http_post -H 'Content-Type: application/json' -d "$payload"
}

notice_showdoc_text() {
  local content=${CONTENT//$'\n'/<br>}
  http_post \
    --data-urlencode "title=$CONTENT_TITLE" \
    --data-urlencode "content=$content"
}

######################################################################
# Markdown通知
######################################################################
# 使用飞书的富文本代替Markdown
notice_feishu_markdown() {
  local payload
  payload=$(json_payload \
    --arg title "$CONTENT_TITLE" \
    --arg repo "$REPO" \
    --arg repoUrl "$REPO_URL" \
    --arg branch "$BRANCH" \
    --arg user "$COMMIT_USER" \
    --arg sha "$COMMIT_SHA" \
    --arg message "$COMMIT_MESSAGE" \
    --arg time "$(now)" \
    --arg status "$STATUS_MSG" \
    --arg workflowUrl "$WORKFLOW_URL" \
    '{
      "msg_type": "post",
      "content": {
        "post": {
          "zh_cn": {
            "title": $title,
            "content": [
              [
                {
                  "tag": "text",
                  "text": ""
                }
              ],
              [
                {
                  "tag": "text",
                  "text": "仓库："
                },
                {
                  "tag": "a",
                  "text": $repo,
                  "href": $repoUrl
                }
              ],
              [
                {
                  "tag": "text",
                  "text": "分支："
                },
                {
                  "tag": "text",
                  "text": $branch
                }
              ],
              [
                {
                  "tag": "text",
                  "text": "作者："
                },
                {
                  "tag": "text",
                  "text": $user
                }
              ],
              [
                {
                  "tag": "text",
                  "text": "哈希："
                },
                {
                  "tag": "text",
                  "text": $sha
                }
              ],
              [
                {
                  "tag": "text",
                  "text": "信息："
                },
                {
                  "tag": "text",
                  "text": $message
                }
              ],
              [
                {
                  "tag": "text",
                  "text": "时间："
                },
                {
                  "tag": "text",
                  "text": $time
                }
              ],
              [
                {
                  "tag": "text",
                  "text": "状态："
                },
                {
                  "tag": "text",
                  "text": $status
                }
              ],
              [
                {
                  "tag": "text",
                  "text": "详情："
                },
                {
                  "tag": "a",
                  "text": "查看流水线",
                  "href": $workflowUrl
                }
              ]
            ]
          }
        }
      }
    }')
  http_post -H 'Content-Type: application/json' -d "$payload"
}

notice_workWechat_markdown() {
  local content payload
  content="## <font color='$COLOR'>$CONTENT_TITLE</font>

仓库：[$REPO]($REPO_URL)
分支：$BRANCH
作者：$COMMIT_USER
哈希：$COMMIT_SHA
信息：$COMMIT_MESSAGE
时间：$(now)
状态：$STATUS_MSG
详情：[查看流水线]($WORKFLOW_URL)"

  payload=$(json_payload --arg content "$content" '{
    "msgtype": "markdown",
    "markdown": {
      "content": $content
    }
  }')
  http_post -H 'Content-Type: application/json' -d "$payload"
}

notice_dingtalk_markdown() {
  local content payload
  content="### <font color='$COLOR'>$CONTENT_TITLE</font>
<br>仓库：[$REPO]($REPO_URL)<br>分支：$BRANCH<br>作者：$COMMIT_USER<br>哈希：$COMMIT_SHA<br>信息：$COMMIT_MESSAGE<br>时间：$(now)<br>状态：$STATUS_MSG<br>详情：[查看流水线]($WORKFLOW_URL)"

  payload=$(json_payload \
    --arg title "$CONTENT_TITLE" \
    --arg text "$content" \
    '{
      "msgtype": "markdown",
      "markdown": {
        "title": $title,
        "text": $text
      }
    }')
  http_post -H 'Content-Type: application/json' -d "$payload"
}

notice_showdoc_markdown() {
  local content
  content="### <font color='$COLOR'>$CONTENT_TITLE</font>

仓库：[$REPO]($REPO_URL)
分支：$BRANCH
作者：$COMMIT_USER
哈希：$COMMIT_SHA
信息：$COMMIT_MESSAGE
时间：$(now)
状态：$STATUS_MSG
详情：[查看流水线]($WORKFLOW_URL)"

  http_post \
    --data-urlencode "title=$CONTENT_TITLE" \
    --data-urlencode "content=$content"
}

######################################################################
# 卡片通知
######################################################################
notice_feishu_card() {
  local content payload
  content="分支：$BRANCH
信息：$COMMIT_MESSAGE
哈希：$COMMIT_SHA
作者：$COMMIT_USER
时间：$(now)
状态：$STATUS_MSG"

  payload=$(json_payload \
    --arg repo "$REPO" \
    --arg repoUrl "$REPO_URL" \
    --arg content "$content" \
    --arg workflowUrl "$WORKFLOW_URL" \
    --arg title "$CONTENT_TITLE" \
    --arg color "$COLOR" \
    '{
      "msg_type": "interactive",
      "card": {
        "config": {
          "update_multi": true
        },
        "i18n_elements": {
          "zh_cn": [
            {
              "tag": "action",
              "actions": [
                {
                  "tag": "button",
                  "text": {
                    "tag": "plain_text",
                    "content": $repo
                  },
                  "type": "primary_text",
                  "width": "default",
                  "size": "medium",
                  "behaviors": [
                    {
                      "type": "open_url",
                      "default_url": $repoUrl
                    }
                  ]
                }
              ]
            },
            {
              "tag": "markdown",
              "content": $content,
              "text_align": "left",
              "text_size": "normal"
            },
            {
              "tag": "action",
              "actions": [
                {
                  "tag": "button",
                  "text": {
                    "tag": "plain_text",
                    "content": "查看流水线"
                  },
                  "type": "primary",
                  "width": "default",
                  "size": "medium",
                  "behaviors": [
                    {
                      "type": "open_url",
                      "default_url": $workflowUrl
                    }
                  ]
                }
              ]
            }
          ]
        },
        "i18n_header": {
          "zh_cn": {
            "title": {
              "tag": "plain_text",
              "content": $title
            },
            "subtitle": {
              "tag": "plain_text",
              "content": ""
            },
            "template": $color
          }
        }
      }
    }')
  http_post -H 'Content-Type: application/json' -d "$payload"
}

######################################################################
# 程序调用执行
######################################################################
case "$NOTICE_TYPE" in
  feishu) # 飞书
    case "$MSG_TYPE" in
      text) notice_feishu_text ;;
      markdown) notice_feishu_markdown ;;
      card) notice_feishu_card ;;
    esac
    ;;
  dingtalk) # 钉钉
    case "$MSG_TYPE" in
      text) notice_dingtalk_text ;;
      markdown) notice_dingtalk_markdown ;;
    esac
    ;;
  workwechat) # 企业微信
    case "$MSG_TYPE" in
      text) notice_workWechat_text ;;
      markdown) notice_workWechat_markdown ;;
    esac
    ;;
  showdoc) # showDoc
    case "$MSG_TYPE" in
      text) notice_showdoc_text ;;
      markdown) notice_showdoc_markdown ;;
    esac
    ;;
  *)
    echo "Error: Invalid NOTICE_TYPE provided."
    exit 1
    ;;
esac



######################################################################
# CD Deployments 执行完毕
######################################################################
log_info() {
  echo -e "\033[0;32m\033[1m $1 \033[0m"
}
log_info "🚀🚀🚀 Notice 执行完毕"

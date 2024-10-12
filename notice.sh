#!/bin/bash
set -e
NOTICE_TYPE="$1"
MSG_TYPE="$2"

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
  echo "  card        Send a card-style notification."
  echo ""
  exit 1
}

if [[ "$ACTION" == "--help" ]]; then
  print_usage
  exit 0
fi

print_env() {
  echo "--------------------------------------------------------------------------"
  echo "  Shell Notification < Initialization Parameters >"
  echo "--------------------------------------------------------------------------"
  echo "  STATUS: $STATUS"
  echo "  REPO: $REPO"
  echo "  REPO_URL: $REPO_URL"
  echo "  BRANCH: $BRANCH"
  echo "  COMMIT_USER: $COMMIT_USER"
  echo "  COMMIT_MESSAGE: $COMMIT_MESSAGE"
  echo "  WORKFLOW_URL: $WORKFLOW_URL"
  echo "  TRIGGER_TIME: $TRIGGER_TIME"
  echo "--------------------------------------------------------------------------"
  echo "  NOTICE_TYPE: $NOTICE_TYPE"
  echo "  MSG_TYPE: $MSG_TYPE"
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
if [[ "$NOTICE_TYPE" != "feishu" && "$NOTICE_TYPE" != "dingtalk" && "$NOTICE_TYPE" != "workWechat" && "$NOTICE_TYPE" != "showDoc" ]]; then
  echo "Error: NOTICE_TYPE parameter validation error."
  exit 1
fi

# 检查执行动作
if [[ "$MSG_TYPE" != "text" && "$MSG_TYPE" != "markdown" && "$MSG_TYPE" != "card" ]]; then
  echo "Error: MSG_TYPE parameter validation error."
  exit 1
fi

# 环境变量
COMMIT_MESSAGE=$(echo "$COMMIT_MESSAGE" | tr -d '\n')

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

if [[ "$STATUS" != "1" && "$STATUS" != "0" ]]; then
  echo "Error: 参数 STATUS 必须是 0 或者 1"
  exit 1
fi

if [[ "$STATUS" == "1" ]]; then
  STATUS_MSG="成功"
  CONTENT_TITLE="部署成功通知"
  COLOR="green"
else
  STATUS_MSG="失败"
  CONTENT_TITLE="部署失败通知"
  COLOR="red"
fi


######################################################################
# 文本通知
######################################################################
TRIGGER_TIME="$(TZ="Asia/Shanghai" date +"%Y-%m-%d %H:%M:%S")"
CONTENT="$CONTENT_TITLE \n\n仓库: $REPO \n分支: $BRANCH \n作者: $COMMIT_USER \n状态: $STATUS_MSG \n信息: $COMMIT_MESSAGE \n时间: $TRIGGER_TIME \n详情: $WORKFLOW_URL "

notice_feishu_text() {
  curl -X POST "$WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d '{
     "msg_type": "text",
     "content": {
       "text": "'"$CONTENT"'"
     }
    }'
}

notice_workWechat_text() {
  curl -X POST "$WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d '{
        "msgtype": "text",
        "text": {
            "content": "'"$CONTENT"'"
        }
    }'
}

notice_dingtalk_text() {
  curl -X POST "$WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d '{
        "msgtype": "text",
        "text": {
            "content": "'"$CONTENT"'"
        }
    }'
}

notice_showdoc_text() {
#  CONTENT=$(echo "$CONTENT" | sed ':a;N;$!ba;s/\\n/<br>/g')
#  CONTENT=$(echo "$CONTENT" | sed 's/\\n/<br>/g')
  CONTENT=${CONTENT//\\n/<br>}
  curl -X POST "$WEBHOOK_URL" \
    -d "title=$CONTENT_TITLE&content=$CONTENT"
}

######################################################################
# Markdown通知
######################################################################
# 使用飞书的富文本代替Markdown
notice_feishu_markdown() {
  curl -X POST "$WEBHOOK_URL"  \
     -H 'Content-Type: application/json' \
     -d '{
       "msg_type": "post",
       "content": {
         "post": {
           "zh_cn": {
             "title": "'"$CONTENT_TITLE"'",
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
                   "text": "'"$REPO"'",
                   "href": "'"$REPO_URL"'"
                 }
               ],
               [
                 {
                   "tag": "text",
                   "text": "分支："
                 },
                 {
                   "tag": "text",
                   "text": "'"$BRANCH"'"
                 }
               ],
               [
                 {
                   "tag": "text",
                   "text": "哈希："
                 },
                 {
                   "tag": "text",
                   "text": "'"$COMMIT_SHA"'"
                 }
               ],
               [
                 {
                   "tag": "text",
                   "text": "信息："
                 },
                 {
                   "tag": "text",
                   "text": "'"$COMMIT_MESSAGE"'"
                 }
               ],
               [
                 {
                   "tag": "text",
                   "text": "作者："
                 },
                 {
                   "tag": "text",
                   "text": "'"$COMMIT_USER"'"
                 }
               ],
               [
                 {
                   "tag": "text",
                   "text": "时间："
                 },
                 {
                   "tag": "text",
                   "text": "'"$(TZ="Asia/Shanghai" date +"%Y-%m-%d %H:%M:%S")"'"
                 }
               ],
               [
                 {
                   "tag": "text",
                   "text": "状态："
                 },
                 {
                   "tag": "text",
                   "text": "'"$STATUS_MSG"'"
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
                   "href": "'"$WORKFLOW_URL"'"
                 }
               ]
             ]
           }
         }
       }
     }'
}

notice_workWechat_markdown() {
  CONTENT="## <font color='$COLOR'>$CONTENT_TITLE</font>
\n
仓库：[$REPO]($REPO_URL)
分支：$BRANCH
信息：$COMMIT_MESSAGE
哈希：$COMMIT_SHA
作者：$COMMIT_USER
时间：$(TZ="Asia/Shanghai" date +"%Y-%m-%d %H:%M:%S")
状态：$STATUS_MSG
详情：[查看流水线]($WORKFLOW_URL)"

  curl -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d '{
      "msgtype": "markdown",
      "markdown": {
          "content": "'"$CONTENT"'"
      }
  }'
}

notice_dingtalk_markdown() {
  CONTENT="### <font color='$COLOR'>$CONTENT_TITLE</font>
<br>仓库：[$REPO]($REPO_URL)<br>分支：$BRANCH <br>信息：$COMMIT_MESSAGE <br>哈希：$COMMIT_SHA <br>作者：$COMMIT_USER <br>时间：$(TZ="Asia/Shanghai" date +"%Y-%m-%d %H:%M:%S") <br>状态：$STATUS_MSG <br>详情：[查看流水线]($WORKFLOW_URL)"

  curl -X POST "$WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d '{
        "msgtype": "markdown",
        "markdown": {
            "title":"'"$CONTENT_TITLE"'",
            "text": "'"$CONTENT"'"
        }
    }'
}

notice_showdoc_markdown() {
    CONTENT="### <font color='$COLOR'>$CONTENT_TITLE</font>

仓库：[$REPO]($REPO_URL)
分支：$BRANCH
信息：$COMMIT_MESSAGE
哈希：$COMMIT_SHA
作者：$COMMIT_USER
时间：$(TZ="Asia/Shanghai" date +"%Y-%m-%d %H:%M:%S")
状态：$STATUS_MSG
详情：[查看流水线]($WORKFLOW_URL)"

  curl -X POST "$WEBHOOK_URL" \
    -d "title=$CONTENT_TITLE&content=$CONTENT"
}


######################################################################
# 卡片通知
######################################################################
notice_feishu_card() {
  CONTENT="分支：$BRANCH \n信息：$COMMIT_MESSAGE \n哈希：$COMMIT_SHA \n作者：$COMMIT_USER \n时间：$(TZ="Asia/Shanghai" date +"%Y-%m-%d %H:%M:%S") \n状态：$STATUS_MSG "

  curl -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d '{
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
                                  "content": "'"$REPO"'"
                              },
                              "type": "primary_text",
                              "width": "default",
                              "size": "medium",
                              "behaviors": [
                                  {
                                      "type": "open_url",
                                      "default_url": "'"$REPO_URL"'"
                                  }
                              ]
                          }
                      ]
                  },
                  {
                      "tag": "markdown",
                      "content": "'"$CONTENT"'",
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
                                      "default_url": "'"$WORKFLOW_URL"'"
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
                      "content": "'"$CONTENT_TITLE"'"
                  },
                  "subtitle": {
                      "tag": "plain_text",
                      "content": ""
                  },
                  "template": "'"$COLOR"'"
              }
          }
      }
    }'
}


######################################################################
# 程序调用执行
######################################################################
case $NOTICE_TYPE in
  feishu) # 飞书
    if [[ "$MSG_TYPE" == "text" ]]; then
      notice_feishu_text
    elif [[ "$MSG_TYPE" == "markdown" ]]; then
      notice_feishu_markdown
    elif [[ "$MSG_TYPE" == "card" ]]; then
      notice_feishu_card
    else
      echo "Error: Invalid MSG_TYPE provided."
      exit 1
    fi
    ;;
  dingtalk) # 钉钉
    if [[ "$MSG_TYPE" == "text" ]]; then
      notice_dingtalk_text
    elif [[ "$MSG_TYPE" == "markdown" ]]; then
      notice_dingtalk_markdown
    else
      echo "Error: Invalid MSG_TYPE provided."
      exit 1
    fi
    ;;
  workWechat) # 企业微信
    if [[ "$MSG_TYPE" == "text" ]]; then
      notice_workWechat_text
    elif [[ "$MSG_TYPE" == "markdown" ]]; then
      notice_workWechat_markdown
    else
      echo "Error: Invalid MSG_TYPE provided."
      exit 1
    fi
    ;;
  showDoc) # showDoc
    if [[ "$MSG_TYPE" == "text" ]]; then
      notice_showdoc_text
    elif [[ "$MSG_TYPE" == "markdown" ]]; then
      notice_showdoc_markdown
    else
      echo "Error: Invalid MSG_TYPE provided."
      exit 1
    fi
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
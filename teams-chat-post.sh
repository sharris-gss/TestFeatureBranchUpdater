#!/bin/bash
# =============================================================================
#  Author: Chu-Siang Lai / chusiang (at) drx.tw
#  Filename: teams-chat-post.sh
#  Modified: 2021-10-18 00:09
#  Description: Post a message to Microsoft Teams.
#  Reference:
#
#   - https://gist.github.com/chusiang/895f6406fbf9285c58ad0a3ace13d025
#
# =============================================================================

# Help.
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  echo 'Usage: teams-chat-post.sh "<webhook_url>" "<title>" "<color>" "<message>"'
  exit 0
fi

# Webhook or Token.
WEBHOOK_URL=$1
if [[ "${WEBHOOK_URL}" == "" ]]
then
  echo "No webhook_url specified."
  exit 1
fi
shift

# Title .
TITLE=$1
if [[ "${TITLE}" == "" ]]
then
  echo "No title specified."
  exit 1
fi
shift

# Color.
COLOR=$1
if [[ "${COLOR}" == "" ]]
then
  echo "No status specified."
  exit 1
fi
shift

# Text.
TEXT=$*
if [[ "${TEXT}" == "" ]]
then
  echo "No text specified."
  exit 1
fi

# Convert formating.
MESSAGE=$( echo ${TEXT} | sed 's/"/\"/g' | sed "s/'/\'/g" )
JSON="{\"title\": \"$TITLE\", \"themeColor\": \"$COLOR\", \"text\": \"$MESSAGE\" }"
echo $JSON

# Post to Microsoft Teams.
curl -X POST -H "Content-Type: application/json" -d "${JSON}" "${WEBHOOK_URL}"
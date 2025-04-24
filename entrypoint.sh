#!/bin/bash
set -e

echo "🔍 Checking Quay repo: $QUAY_REPO for tag: $COMMIT_SHA"

DELAY=${DELAY_MINUTES:-10}
RETRIES=${RETRIES:-20}
INTERVAL=${INTERVAL_MINUTES:-1}

if [[ "$QUAY_PRIVATE" == "true" ]]; then
  if [[ -z "$QUAY_TOKEN" ]]; then
    echo "❌ Quay repo is private, but no token provided"
    exit 1
  fi
  AUTH_HEADER="Authorization: Bearer $QUAY_TOKEN"
else
  AUTH_HEADER=""
fi

# Initial delay
echo "🕒 Waiting initial delay: ${DELAY} minutes..."

remaining=$DELAY
while [ $remaining -gt 0 ]; do
  printf "\r⏳ Waiting: %2d minutes remaining..." "$remaining"
  sleep 60
  remaining=$((remaining - 1))
done

echo -e "\n✅ Initial delay completed."

for ((i=1;i<=RETRIES;i++)); do
  echo "🔁 Attempt $i/$RETRIES..."

  if curl -s -H "$AUTH_HEADER" "https://quay.io/api/v1/repository/${QUAY_REPO}/tag/?onlyActiveTags=true&specificTag=${COMMIT_SHA}" | grep -q "${COMMIT_SHA}"; then
    echo "✅ Quay image with tag ${COMMIT_SHA} was found in repository ${QUAY_REPO}."

    exit 0
  fi

  echo "⏳ Tag not found yet, waiting ${INTERVAL} minutes..."
  sleep "${INTERVAL}m"
done

TOTAL_TIME=$((DELAY + RETRIES * INTERVAL))
QUAY_REPO_URL="https://quay.io/repository/$QUAY_REPO"
echo "❌ Image with tag $COMMIT_SHA was NOT found in repository $QUAY_REPO_URL after ${TOTAL_TIME} minutes from PR merge."

if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
  echo "📢 Sending Slack notification..."
  curl -X POST -H 'Content-type: application/json' --data "{
    \"text\": \"❌ Quay image with tag *$COMMIT_SHA* was NOT created in repository <$QUAY_REPO_URL> after ${TOTAL_TIME} minutes from PR merge. Commit: <$GITHUB_COMMIT_URL>\"
  }" "$SLACK_WEBHOOK_URL"
fi

exit 1

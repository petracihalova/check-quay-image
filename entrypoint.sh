#!/bin/bash
set -e

# Check if the PR was merged (skip if closed)
if [[ "$PR_MERGED" != "true" ]]; then
  echo "❌ PR was not merged, skipping Quay image check"
  exit 0
fi

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
sleep "${DELAY}m"

for ((i=1;i<=RETRIES;i++)); do
  echo "🔁 Attempt $i/$RETRIES..."

  RESPONSE=$(curl -s -H "$AUTH_HEADER" "https://quay.io/api/v1/repository/${QUAY_REPO}/tag/?onlyActiveTags=true")
  TAG_FOUND=$(echo "$RESPONSE" | jq -r ".tags[]?.name" | grep -Fx "$COMMIT_SHA" || true)

  if [[ -n "$TAG_FOUND" ]]; then
    echo "✅ Image with tag $COMMIT_SHA found in $QUAY_REPO"
    exit 0
  fi

  echo "⏳ Tag not found yet, waiting ${INTERVAL} minutes..."
  sleep "${INTERVAL}m"
done

echo "❌ Image with tag $COMMIT_SHA was NOT found in repository $QUAY_REPO after ${TOTAL_TIME} minutes from PR merge."

if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
  echo "📢 Sending Slack notification..."
  QUAY_REPO_URL="https://quay.io/repository/$QUAY_REPO"
  TOTAL_MINUTES=$((DELAY + RETRIES * INTERVAL))
  curl -X POST -H 'Content-type: application/json' --data "{
    \"text\": \"❌ Quay image with tag *$COMMIT_SHA* was NOT created in repository *$QUAY_REPO* after ${TOTAL_TIME} minutes from PR merge. Check the PR here: <$GITHUB_PR_URL>\"
  }" "$SLACK_WEBHOOK_URL"
fi

exit 1

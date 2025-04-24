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

echo "❌ Image with tag $COMMIT_SHA not found after $RETRIES attempts"
exit 1

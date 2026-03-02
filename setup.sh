#!/bin/bash
# ----------------------------------------------------------------
# 🚀 Jubilant-Invention: Ntfy Git Push Automator
# Version: 1.0.0 | Created by jvhn0gl3
# ----------------------------------------------------------------

CURRENT_VERSION="1.0.0"
BASE_URL="https://raw.githubusercontent.com/jvhn0gl3/jubilant-invention/main"
NTFY_TOPIC="flux" # Set during setup.sh

# 1. Version & Changelog Check (2s timeout to prevent lag)
REMOTE_VERSION=$(curl -s --connect-timeout 2 "$BASE_URL/version.txt" || echo "$CURRENT_VERSION")
UPDATE_INFO=""

if [ "$REMOTE_VERSION" != "$CURRENT_VERSION" ]; then
    CHANGELOG=$(curl -s --connect-timeout 2 "$BASE_URL/changelog.txt" || echo "New updates available!")
    UPDATE_INFO="✨ NEW VERSION: $REMOTE_VERSION\n📝 WHAT'S NEW: $CHANGELOG\n👉 Run setup.sh to update."
fi

# 2. Gather Project Context
PROJECT_NAME=$(basename "$(pwd)")
MSG=$(git log -1 --pretty=%B)
HASH=$(git rev-parse HEAD)
SHORT_HASH=$(git rev-parse --short HEAD)
BRANCH=$(git branch --show-current)
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# 3. Get GitHub URL & File Inventory
REPO_URL=$(git config --get remote.origin.url | sed 's/git@github.com:/https:\/\/github.com\//;s/\.git$//')
FILES_CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD | head -n 3)
FILE_COUNT=$(git diff-tree --no-commit-id --name-only -r HEAD | wc -l)

# 4. Push & Notify
if git push origin "$BRANCH"; then
    curl -H "Title: ✅ $PROJECT_NAME Updated" \
         -H "Priority: default" \
         -H "Tags: white_check_mark,gear" \
         -H "Click: $REPO_URL" \
         -H "Actions: view, View Diff, $REPO_URL/commit/$HASH, clear=true" \
         -d "📍 Profile: $PROJECT_NAME
⏰ Time: $TIMESTAMP
💬 Msg: $MSG

📄 Files Changed ($FILE_COUNT):
$FILES_CHANGED

$UPDATE_INFO" \
         ntfy.sh/$NTFY_TOPIC
else
    curl -H "Title: ❌ $PROJECT_NAME: Push Failed" \
         -H "Priority: high" \
         -H "Tags: x,warning" \
         -d "The push for $PROJECT_NAME failed at $TIMESTAMP." \
         ntfy.sh/$NTFY_TOPIC
    exit 1
fi

#!/bin/bash
echo "------------------------------------------------"
echo "  🚀 Jubilant-Invention: Setup Assistant        "
echo "------------------------------------------------"

read -p "Enter your ntfy topic (e.g., flux): " USER_TOPIC

if [ -z "$USER_TOPIC" ]; then
    echo "❌ Error: Topic cannot be empty."
    exit 1
fi

# Create the core script
cat << INNER_EOF > ~/send_commit.sh
#!/bin/bash
CURRENT_VERSION="1.0.0"
BASE_URL="https://raw.githubusercontent.com/jvhn0gl3/jubilant-invention/main"
NTFY_TOPIC="$USER_TOPIC"

# 1. Version Check
REMOTE_VERSION=\$(curl -s --connect-timeout 2 "\$BASE_URL/version.txt" || echo "\$CURRENT_VERSION")
UPDATE_INFO=""
if [ "\$REMOTE_VERSION" != "\$CURRENT_VERSION" ]; then
    CHANGELOG=\$(curl -s --connect-timeout 2 "\$BASE_URL/changelog.txt" || echo "New updates available!")
    UPDATE_INFO="✨ NEW VERSION: \$REMOTE_VERSION\n📝 WHAT'S NEW: \$CHANGELOG\n👉 Re-run setup.sh to update."
fi

# 2. Context Data
PROJECT_NAME=\$(basename "\$(pwd)")
MSG=\$(git log -1 --pretty=%B)
HASH=\$(git rev-parse HEAD)
SHORT_HASH=\$(git rev-parse --short HEAD)
BRANCH=\$(git branch --show-current)
TIMESTAMP=\$(date "+%Y-%m-%d %H:%M:%S")
REPO_URL=\$(git config --get remote.origin.url | sed 's/git@github.com:/https:\/\/github.com\//;s/\\.git$//')
FILES_CHANGED=\$(git diff-tree --no-commit-id --name-only -r HEAD | head -n 3)
FILE_COUNT=\$(git diff-tree --no-commit-id --name-only -r HEAD | wc -l)

# 3. Push & Notify
if git push origin "\$BRANCH"; then
    curl -H "Title: ✅ \$PROJECT_NAME Updated" \\
         -H "Priority: default" \\
         -H "Tags: white_check_mark,gear" \\
         -H "Click: \$REPO_URL" \\
         -H "Actions: view, View Diff, \$REPO_URL/commit/\$HASH, clear=true" \\
         -d "📍 Profile: \$PROJECT_NAME
⏰ Time: \$TIMESTAMP
💬 Msg: \$MSG

📄 Files Changed (\$FILE_COUNT):
\$FILES_CHANGED

\$UPDATE_INFO" \\
         ntfy.sh/\$NTFY_TOPIC
else
    curl -H "Title: ❌ \$PROJECT_NAME: Push Failed" \\
         -H "Priority: high" \\
         -H "Tags: x,warning" \\
         -d "The push for \$PROJECT_NAME failed at \$TIMESTAMP." \\
         ntfy.sh/\$NTFY_TOPIC
    exit 1
fi
INNER_EOF

chmod +x ~/send_commit.sh
grep -qxF "alias gpush='bash ~/send_commit.sh'" ~/.bashrc || echo "alias gpush='bash ~/send_commit.sh'" >> ~/.bashrc
echo "✅ Setup Complete! Run 'source ~/.bashrc' then use 'gpush'."

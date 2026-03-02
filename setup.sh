#!/bin/bash
echo "------------------------------------------------"
echo "  🚀 Jubilant-Invention: Setup Assistant        "
echo "------------------------------------------------"

read -p "Enter your ntfy topic (e.g., flux): " USER_TOPIC

if [ -z "$USER_TOPIC" ]; then
    echo "❌ Error: Topic cannot be empty."
    exit 1
fi

cat << INNER_EOF > ~/send_commit.sh
#!/bin/bash
CURRENT_VERSION="1.2.0"
BASE_URL="https://raw.githubusercontent.com/jvhn0gl3/jubilant-invention/main"
NTFY_TOPIC="$USER_TOPIC"

# --- AUTO-UPDATE CHECK ---
REMOTE_VERSION=\$(curl -s --connect-timeout 2 "\$BASE_URL/version.txt" || echo "\$CURRENT_VERSION")

if [ "\$REMOTE_VERSION" != "\$CURRENT_VERSION" ]; then
    echo "✨ Update found (\$REMOTE_VERSION). Updating script..."
    CHANGELOG=\$(curl -s --connect-timeout 2 "\$BASE_URL/changelog.txt" || echo "New improvements!")
    
    # Download the latest setup.sh and run it silently to update
    curl -sL "\$BASE_URL/setup.sh" | bash -s -- "\$NTFY_TOPIC"
    
    curl -H "Title: 🚀 Jubilant-Invention: Auto-Updated" \\
         -H "Priority: default" \\
         -H "Tags: sparkle,up" \\
         -d "Updated to \$REMOTE_VERSION: \$CHANGELOG" \\
         ntfy.sh/\$NTFY_TOPIC
    
    # Restart the command with the new script
    exec bash "\$0" "\$@"
fi

# --- TEST MODE ---
if [ "\$1" == "--test" ]; then
    curl -H "Title: 🛠️ Test Successful" -d "Setup is live for \$NTFY_TOPIC." ntfy.sh/\$NTFY_TOPIC
    exit 0
fi

# --- CORE LOGIC ---
PROJECT_NAME=\$(basename "\$(pwd)")
MSG=\$(git log -1 --pretty=%B)
HASH=\$(git rev-parse HEAD)
SHORT_HASH=\$(git rev-parse --short HEAD)
BRANCH=\$(git branch --show-current)
TIMESTAMP=\$(date "+%Y-%m-%d %H:%M:%S")
REPO_URL=\$(git config --get remote.origin.url | sed 's/git@github.com:/https:\/\/github.com\//;s/\\.git$//')

if git push origin "\$BRANCH"; then
    curl -H "Title: ✅ \$PROJECT_NAME Updated" \\
         -H "Tags: white_check_mark,gear" \\
         -H "Actions: view, View Diff, \$REPO_URL/commit/\$HASH, clear=true" \\
         -d "📍 Profile: \$PROJECT_NAME | ⏰ \$TIMESTAMP\n🆔 \$SHORT_HASH: \$MSG" \\
         ntfy.sh/\$NTFY_TOPIC
else
    curl -H "Title: ❌ \$PROJECT_NAME: Push Failed" -H "Priority: high" -H "Tags: x" -d "Push failed at \$TIMESTAMP." ntfy.sh/\$NTFY_TOPIC
    exit 1
fi
INNER_EOF

chmod +x ~/send_commit.sh
grep -qxF "alias gpush='bash ~/send_commit.sh'" ~/.bashrc || echo "alias gpush='bash ~/send_commit.sh'" >> ~/.bashrc
echo "✅ Setup Complete (v1.2.0) with Auto-Update enabled."

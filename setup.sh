#!/bin/bash
# ----------------------------------------------------------------
# 🚀 Jubilant-Invention: Ntfy Git Push Automator Setup
# Created by jvhn0gl3
# ----------------------------------------------------------------

echo "------------------------------------------------"
echo "  Setting up your Git -> Ntfy Automator...      "
echo "------------------------------------------------"

# Ask for the user's ntfy topic
read -p "Enter your ntfy topic (e.g., flux): " USER_TOPIC

if [ -z "$USER_TOPIC" ]; then
    echo "❌ Error: Topic cannot be empty. Setup cancelled."
    exit 1
fi

# Create the core script with the user's topic embedded
cat << INNER_EOF > ~/send_commit.sh
#!/bin/bash
# 1. Variables
PROJECT_NAME=\$(basename "\$(pwd)")
MSG=\$(git log -1 --pretty=%B)
HASH=\$(git rev-parse HEAD)
SHORT_HASH=\$(git rev-parse --short HEAD)
BRANCH=\$(git branch --show-current)
TIMESTAMP=\$(date "+%Y-%m-%d %H:%M:%S")

# 2. Get GitHub URL (Auto-mapping)
REPO_URL=\$(git config --get remote.origin.url | sed 's/git@github.com:/https:\/\/github.com\//;s/\.git$//')

# 3. Get Changed Files (Top 5)
FILES_CHANGED=\$(git diff-tree --no-commit-id --name-only -r HEAD | head -n 5)
FILE_COUNT=\$(git diff-tree --no-commit-id --name-only -r HEAD | wc -l)

# 4. Push & Notify
if git push origin "\$BRANCH"; then
    curl -H "Title: ✅ \$PROJECT_NAME: \$BRANCH Updated" \\
         -H "Priority: default" \\
         -H "Tags: white_check_mark,hammer_and_wrench" \\
         -H "Click: \$REPO_URL" \\
         -H "Actions: view, View Diff, \$REPO_URL/commit/\$HASH, clear=true" \\
         -d "📍 Profile: \$PROJECT_NAME
⏰ Time: \$TIMESTAMP
🆔 Commit: \$SHORT_HASH
💬 Msg: \$MSG

📄 Files Changed (\$FILE_COUNT):
\$FILES_CHANGED" \\
         ntfy.sh/$USER_TOPIC
else
    curl -H "Title: ❌ \$PROJECT_NAME: Push Failed" \\
         -H "Priority: high" \\
         -H "Tags: x,warning" \\
         -d "The push for \$PROJECT_NAME failed at \$TIMESTAMP." \\
         ntfy.sh/$USER_TOPIC
    exit 1
fi
INNER_EOF

# Finalizing Installation
chmod +x ~/send_commit.sh

# Add alias to .bashrc if it doesn't exist
grep -qxF "alias gpush='bash ~/send_commit.sh'" ~/.bashrc || echo "alias gpush='bash ~/send_commit.sh'" >> ~/.bashrc

echo "------------------------------------------------"
echo "✅ Setup Complete!"
echo "Topic set to: ntfy.sh/$USER_TOPIC"
echo "Usage: Just type 'gpush' in any git repo."
echo "Note: Run 'source ~/.bashrc' or restart Termux."
echo "------------------------------------------------"


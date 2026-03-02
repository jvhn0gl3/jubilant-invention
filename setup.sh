#!/bin/bash
echo "------------------------------------------------"
echo "  🚀 Jubilant-Invention: Setup Assistant        "
echo "------------------------------------------------"

# Check if a topic was passed as an argument (for auto-updates)
if [ -n "$1" ]; then
    USER_TOPIC="$1"
else
    read -p "Enter your ntfy topic (e.g., flux): " USER_TOPIC
fi

if [ -z "$USER_TOPIC" ]; then
    echo "❌ Error: Topic cannot be empty."
    exit 1
fi

cat << INNER_EOF > ~/send_commit.sh
#!/bin/bash
CURRENT_VERSION="1.3.0"
BASE_URL="https://raw.githubusercontent.com/jvhn0gl3/jubilant-invention/main"
NTFY_TOPIC="$USER_TOPIC"

# --- ARGUMENT CHECKING ---
SILENT=false
TEST_MODE=false

for arg in "\$@"; do
    case \$arg in
        -s|--silent) SILENT=true ;;
        --test) TEST_MODE=true ;;
    esac
done

# --- AUTO-UPDATE CHECK ---
REMOTE_VERSION=\$(curl -s --connect-timeout 2 "\$BASE_URL/version.txt" || echo "\$CURRENT_VERSION")
if [ "\$REMOTE_VERSION" != "\$CURRENT_VERSION" ]; then
    echo "✨ Updating to \$REMOTE_VERSION..."
    curl -sL "\$BASE_URL/setup.sh" | bash -s -- "\$NTFY_TOPIC"
    exec bash "\$0" "\$@"
fi

# --- TEST MODE ---
if [ "\$TEST_MODE" = true ]; then
    curl -H "Title: 🛠️ Test Successful" -d "Setup is live for \$NTFY_TOPIC." ntfy.sh/\$NTFY_TOPIC
    exit 0
fi

# --- CORE LOGIC ---
PROJECT_NAME=\$(basename "\$(pwd)")
BRANCH=\$(git branch --show-current)
MSG=\$(git log -1 --pretty=%B)
HASH=\$(git rev-parse HEAD)
SHORT_HASH=\$(git rev-parse --short HEAD)
TIMESTAMP=\$(date "+%Y-%m-%d %H:%M:%S")
REPO_URL=\$(git config --get remote.origin.url | sed 's/git@github.com:/https:\/\/github.com\//;s/\\.git$//')

if git push origin "\$BRANCH"; then
    if [ "\$SILENT" = false ]; then
        curl -H "Title: ✅ \$PROJECT_NAME Updated" \\
             -H "Tags: white_check_mark,gear" \\
             -H "Actions: view, View Diff, \$REPO_URL/commit/\$HASH, clear=true" \\
             -d "📍 Profile: \$PROJECT_NAME | ⏰ \$TIMESTAMP\n🆔 \$SHORT_HASH: \$MSG" \\
             ntfy.sh/\$NTFY_TOPIC
    else
        echo "Push successful (Silent Mode: No notification sent)."
    fi
else
    curl -H "Title: ❌ \$PROJECT_NAME: Push Failed" -H "Priority: high" -H "Tags: x" -d "Push failed at \$TIMESTAMP." ntfy.sh/\$NTFY_TOPIC
    exit 1
fi
INNER_EOF

chmod +x ~/send_commit.sh
grep -qxF "alias gpush='bash ~/send_commit.sh'" ~/.bashrc || echo "alias gpush='bash ~/send_commit.sh'" >> ~/.bashrc
echo "✅ Setup Complete (v1.3.0). Silent mode ready."

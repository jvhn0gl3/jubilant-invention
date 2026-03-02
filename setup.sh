#!/bin/bash
echo "------------------------------------------------"
echo "  🚀 Jubilant-Invention: Setup Assistant        "
echo "------------------------------------------------"

if [ -n "$1" ]; then USER_TOPIC="$1"; else read -p "Enter your ntfy topic: " USER_TOPIC; fi
[ -z "$USER_TOPIC" ] && exit 1

cat << INNER_EOF > ~/send_commit.sh
#!/bin/bash
CURRENT_VERSION="1.4.0"
BASE_URL="https://raw.githubusercontent.com/jvhn0gl3/jubilant-invention/main"
NTFY_TOPIC="$USER_TOPIC"

# --- HELP MENU ---
show_help() {
    echo "Jubilant-Invention v\$CURRENT_VERSION"
    echo "Usage: gpush [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -s, --silent    Push to GitHub without ntfy notification"
    echo "  --test          Send a test notification to verify setup"
    echo "  --version       Display the current script version"
    exit 0
}

# --- ARGUMENT CHECKING ---
for arg in "\$@"; do
    case \$arg in
        -h|--help) show_help ;;
        --version) echo "v\$CURRENT_VERSION"; exit 0 ;;
        -s|--silent) SILENT=true ;;
        --test) TEST_MODE=true ;;
    esac
done

# --- AUTO-UPDATE CHECK ---
REMOTE_VERSION=\$(curl -s --connect-timeout 2 "\$BASE_URL/version.txt" || echo "\$CURRENT_VERSION")
if [ "\$REMOTE_VERSION" != "\$CURRENT_VERSION" ]; then
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
REPO_URL=\$(git config --get remote.origin.url | sed 's/git@github.com:/https:\/\/github.com\//;s/\\.git$//')

if git push origin "\$BRANCH"; then
    [ "\$SILENT" = true ] && exit 0
    curl -H "Title: ✅ \$PROJECT_NAME Updated" \\
         -H "Actions: view, View Diff, \$REPO_URL/commit/\$(git rev-parse HEAD), clear=true" \\
         -d "📍 Profile: \$PROJECT_NAME | 🆔 \$(git rev-parse --short HEAD)" \\
         ntfy.sh/\$NTFY_TOPIC
else
    curl -H "Title: ❌ Push Failed" -H "Priority: high" ntfy.sh/\$NTFY_TOPIC
    exit 1
fi
INNER_EOF

chmod +x ~/send_commit.sh
echo "✅ v1.4.0 Ready."

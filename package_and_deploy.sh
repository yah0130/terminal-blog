#!/bin/bash

set -e

echo "=== Terminal Blog Package & Deploy ==="
echo ""

# Check for sshpass
if ! command -v sshpass &> /dev/null; then
    echo "Installing sshpass..."
    if command -v brew &> /dev/null; then
        brew install sshpass
    else
        echo "Please install sshpass manually:"
        echo "  Ubuntu/Debian: sudo apt install sshpass"
        echo "  Or: brew install sshpass (macOS)"
        exit 1
    fi
fi

# Get server info
echo "Enter server IP or domain:"
read SERVER
echo "Enter SSH port (default 22):"
read PORT
PORT=${PORT:-22}
echo "Enter username:"
read USER

# Build Flutter Web
echo ""
echo "Building Flutter Web..."
cd "$(dirname "$0")"
flutter build web --release
echo "Flutter Web built"

# Build Go API
echo ""
echo "Building Go API..."
cd "$(dirname "$0")/../terminal_blog_api"
GOOS=linux GOARCH=amd64 go build -o terminal_blog_api .
echo "Go API built"

# Create package
echo ""
echo "Creating deployment package..."
cd "$(dirname "$0")"
rm -f /tmp/terminal_blog_deploy.tar.gz
tar -czf /tmp/terminal_blog_deploy.tar.gz \
    build/web \
    ../terminal_blog_api/terminal_blog_api \
    deploy.sh
echo "Package created: /tmp/terminal_blog_deploy.tar.gz"

# Upload to server
echo ""
echo "Uploading to server..."
echo "Enter SSH password:"
sshpass -p "$(read -s password; echo $password)" scp -P $PORT /tmp/terminal_blog_deploy.tar.gz $USER@$SERVER:/tmp/
sshpass -p "$(read -s password; echo $password)" ssh -p $PORT $USER@$SERVER "cd /tmp && tar -xzf terminal_blog_deploy.tar.gz"

# Clean up local password
password=""

echo ""
echo "=== Package & Upload Complete ==="
echo ""
echo "Now SSH to your server and run:"
echo "  sudo bash /tmp/deploy.sh"
echo ""
echo "Or run with ssh:"
echo "  sshpass -p 'YOUR_PASSWORD' ssh -p $PORT $USER@$SERVER sudo bash /tmp/deploy.sh"

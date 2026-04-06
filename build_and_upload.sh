#!/bin/bash

set -e

echo "=== Building & Uploading to Server ==="
echo ""

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
echo "Flutter Web built: build/web/"

# Build Go API for Linux
echo ""
echo "Building Go API for Linux..."
cd "$(dirname "$0")/../terminal_blog_api"
GOOS=linux GOARCH=amd64 go build -o terminal_blog_api .
echo "Go API built: ../terminal_blog_api/terminal_blog_api"

# Create upload package
echo ""
echo "Creating package..."
cd "$(dirname "$0")"
rm -f /tmp/terminal_blog_upload.tar.gz
tar -czf /tmp/terminal_blog_upload.tar.gz \
    build/web \
    ../terminal_blog_api/terminal_blog_api \
    deploy.sh

# Upload
echo ""
echo "Uploading to $USER@$SERVER..."
echo "Enter SSH password:"
read -s PASSWORD

sshpass -p "$PASSWORD" scp -P $PORT /tmp/terminal_blog_upload.tar.gz $USER@$SERVER:/tmp/

echo ""
echo "=== Done ==="
echo ""
echo "Now SSH to your server and run:"
echo "  ssh $USER@$SERVER"
echo "  sudo tar -xzf /tmp/terminal_blog_upload.tar.gz -C /tmp/"
echo "  sudo bash /tmp/deploy.sh"

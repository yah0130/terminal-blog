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

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FLUTTER_DIR="$SCRIPT_DIR"
API_DIR="$(dirname "$SCRIPT_DIR")/terminal_blog_api"

echo "Flutter dir: $FLUTTER_DIR"
echo "API dir: $API_DIR"

# Build Flutter Web
echo ""
echo "Building Flutter Web..."
cd "$FLUTTER_DIR"
flutter build web --release
echo "Flutter Web built: $FLUTTER_DIR/build/web/"

# Build Go API for Linux
echo ""
echo "Building Go API for Linux..."
cd "$API_DIR"
GOOS=linux GOARCH=amd64 go build -o terminal_blog_api .
echo "Go API built: $API_DIR/terminal_blog_api"

# Create upload package
echo ""
echo "Creating package..."
cd /tmp
rm -f terminal_blog_upload.tar.gz
tar -czf terminal_blog_upload.tar.gz \
    -C "$FLUTTER_DIR" build/web \
    -C "$API_DIR" terminal_blog_api \
    -C "$FLUTTER_DIR" deploy.sh

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

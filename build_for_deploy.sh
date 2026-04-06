#!/bin/bash

set -e

echo "=== Building Terminal Blog for Deployment ==="

# Build Flutter Web
echo "Building Flutter Web..."
cd "$(dirname "$0")/terminal_blog"
flutter build web --release
echo "Flutter Web built: terminal_blog/build/web/"

# Build Go API
echo ""
echo "Building Go API..."
cd "$(dirname "$0")/terminal_blog_api"
go build -o terminal_blog_api .
echo "Go API built: terminal_blog_api/terminal_blog_api"

echo ""
echo "=== Build Complete ==="
echo ""
echo "To deploy:"
echo "1. Upload terminal_blog/ and terminal_blog_api/ to your server"
echo "2. Run deploy.sh on your server as root (sudo)"

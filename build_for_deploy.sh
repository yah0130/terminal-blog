#!/bin/bash

set -e

echo "=== Building Terminal Blog for Deployment ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Build Flutter Web
echo "Building Flutter Web..."
cd "$SCRIPT_DIR"
flutter build web --release
echo "Flutter Web built: $SCRIPT_DIR/build/web/"

# Build Go API
echo ""
echo "Building Go API..."
cd "$SCRIPT_DIR/../terminal_blog_api"
go build -o terminal_blog_api .
echo "Go API built: $SCRIPT_DIR/../terminal_blog_api/terminal_blog_api"

echo ""
echo "=== Build Complete ==="
echo ""
echo "To deploy:"
echo "1. Upload build/web/* to your server as /var/www/terminal_blog/"
echo "2. Upload terminal_blog_api/terminal_blog_api to your server as /tmp/terminal_blog_api"
echo "3. Upload deploy.sh to your server as /tmp/deploy.sh"
echo "4. Run: sudo bash /tmp/deploy.sh"

#!/bin/bash

set -e

echo "=== Building Terminal Blog for Deployment ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Build Flutter Web
echo "Building Flutter Web..."
cd "$SCRIPT_DIR"
flutter build web --release
echo "Flutter Web built: $SCRIPT_DIR/build/web/"

echo ""
echo "=== Build Complete ==="
echo ""
echo "To deploy:"
echo "1. Upload build/web/* to your server as /tmp/web/"
echo "2. Upload terminal_blog_api/ folder to your server as /tmp/terminal_blog_api/"
echo "3. Upload deploy.sh to your server as /tmp/deploy.sh"
echo "4. Run: sudo bash /tmp/deploy.sh"

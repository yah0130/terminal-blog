#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Terminal Blog Deployment Script ===${NC}\n"

# Configuration
API_BINARY="terminal_blog_api"
API_PORT=8080
API_DIR="/opt/terminal_blog_api"
API_SERVICE_NAME="terminal-blog-api"
WEB_DIR="/var/www/terminal_blog"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (use sudo)${NC}"
    exit 1
fi

# Detect OS
if [ -f /etc/debian_version ]; then
    OS="debian"
elif [ -f /etc/redhat-release ]; then
    OS="centos"
else
    echo -e "${YELLOW}Unknown OS, assuming Debian/Ubuntu${NC}"
    OS="debian"
fi

install_dependencies() {
    echo -e "${GREEN}[1/6] Installing dependencies...${NC}"
    
    if [ "$OS" == "debian" ]; then
        apt update
        apt install -y nginx postgresql postgresql-contrib curl
    else
        yum install -y nginx postgresql-server postgresql-contrib curl
        postgresql-setup initdb
        systemctl start postgresql
    fi
    
    systemctl enable nginx postgresql
    systemctl start nginx postgresql
    
    echo -e "${GREEN}Dependencies installed${NC}\n"
}

setup_database() {
    echo -e "${GREEN}[2/6] Setting up database...${NC}"
    
    # Create database and user
    sudo -u postgres psql << 'EOF'
CREATE Database terminal_blog;
CREATE User blog_user With Encrypted Password 'blog_password';
Grant All Privileges On Database terminal_blog To blog_user;
\c terminal_blog
Grant All Privileges On All Tables In Schema public To blog_user;
Grant All Privileges On All Sequences In Schema public To blog_user;
EOF

    # Create tables
    sudo -u postgres psql -d terminal_blog << 'EOF'
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE articles (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    date DATE NOT NULL
);

CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE article_tags (
    article_id INT REFERENCES articles(id) ON DELETE CASCADE,
    tag_id INT REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (article_id, tag_id)
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_article_tags_article_id ON article_tags(article_id);
CREATE INDEX idx_article_tags_tag_id ON article_tags(tag_id);
EOF

    echo -e "${GREEN}Database setup complete${NC}\n"
}

create_admin_user() {
    echo -e "${GREEN}[3/6] Setting up admin user...${NC}"
    
    # Check if admin already exists
    ADMIN_EXISTS=$(sudo -u postgres psql -d terminal_blog -t -c "SELECT COUNT(*) FROM users WHERE is_admin = true;")
    ADMIN_EXISTS=$(echo $ADMIN_EXISTS | tr -d ' ')
    
    if [ "$ADMIN_EXISTS" -gt 0 ]; then
        echo -e "${YELLOW}Admin user already exists, skipping creation${NC}"
        ADMIN_EMAIL="skip"
        return 0
    fi
    
    echo "Enter admin email:"
    read ADMIN_EMAIL
    
    echo "Enter admin password:"
    read -s ADMIN_PASSWORD
    
    echo -e "${YELLOW}Admin user will be created when API starts${NC}\n"
}

deploy_api() {
    echo -e "${GREEN}[4/6] Deploying API...${NC}"
    
    # Check if binary was uploaded
    if [ ! -f "/tmp/$API_BINARY" ]; then
        echo -e "${RED}API binary not found in /tmp/. Please upload it first.${NC}"
        exit 1
    fi
    
    # Stop existing service
    systemctl stop "$API_SERVICE_NAME" 2>/dev/null || true
    
    # Copy binary
    mkdir -p "$API_DIR"
    cp "/tmp/$API_BINARY" "$API_DIR/"
    
    # Create systemd service
    cat > /etc/systemd/system/$API_SERVICE_NAME.service << EOF
[Unit]
Description=Terminal Blog API
After=network.target postgresql.service

[Service]
Type=simple
User=www-data
WorkingDirectory=$API_DIR
Environment=DATABASE_URL=postgres://blog_user:blog_password@localhost:5432/terminal_blog
ExecStart=$API_DIR/$API_BINARY
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl start "$API_SERVICE_NAME"
    systemctl enable "$API_SERVICE_NAME"
    
    # Wait for API to start
    sleep 2
    
    # Create admin user via API (only if not exists)
    if [ "$ADMIN_EMAIL" != "skip" ]; then
        echo -e "${GREEN}Creating admin user via API...${NC}"
        ADMIN_RESPONSE=$(curl -s -X POST "http://localhost:$API_PORT/api/register" \
            -H "Content-Type: application/json" \
            -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}")
        
        if echo "$ADMIN_RESPONSE" | grep -q "token"; then
            echo -e "${GREEN}Admin user created: $ADMIN_EMAIL${NC}"
        else
            echo -e "${YELLOW}Admin creation failed. You may need to create it manually.${NC}"
        fi
    fi
    
    echo -e "${GREEN}API deployed${NC}\n"
}

deploy_web() {
    echo -e "${GREEN}[5/6] Deploying Flutter Web...${NC}"
    
    # Check if web files were uploaded
    if [ ! -d "/tmp/web" ]; then
        echo -e "${RED}Flutter Web not found in /tmp/web. Please upload build/web/* first.${NC}"
        exit 1
    fi
    
    # Copy files
    rm -rf "$WEB_DIR"
    mkdir -p "$WEB_DIR"
    cp -r /tmp/web/. "$WEB_DIR/"
    
    echo -e "${GREEN}Flutter Web deployed${NC}\n"
}

configure_nginx() {
    echo -e "${GREEN}[6/6] Configuring Nginx...${NC}"
    
    echo "Enter your domain (e.g., blog.example.com) or press Enter for IP:"
    read DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        DOMAIN=$(curl -s ifconfig.me)
    fi
    
    cat > /etc/nginx/sites-available/terminal-blog << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    root $WEB_DIR;
    index index.html;
    
    # Gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://127.0.0.1:$API_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/terminal-blog /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    systemctl restart nginx
    
    echo -e "${GREEN}Nginx configured${NC}\n"
}

enable_ssl() {
    echo -e "${YELLOW}To enable HTTPS, run:${NC}"
    echo "  sudo certbot --nginx -d $DOMAIN"
    echo "  sudo systemctl restart nginx\n"
}

# Main
install_dependencies
setup_database
create_admin_user
deploy_api
deploy_web
configure_nginx

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "API running on: http://localhost:$API_PORT"
echo -e "Web app at: http://$DOMAIN"
echo ""
enable_ssl

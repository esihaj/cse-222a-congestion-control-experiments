#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Set debconf frontend to noninteractive to suppress warnings
export DEBIAN_FRONTEND=noninteractive

# Define variables
STATIC_SITE_REPO="https://github.com/cloudacademy/static-website-example.git"
WEB_ROOT="/var/www/static-site-example"
NGINX_CONF="/etc/nginx/sites-available/static-site"
NGINX_ENABLED="/etc/nginx/sites-enabled/static-site"
NGINX_DEFAULT_CONF="/etc/nginx/sites-enabled/default"

# Update package lists and install required software if needed
echo "Checking for required software..."
if ! command -v nginx &> /dev/null || ! command -v git &> /dev/null; then
    echo "Installing dependencies..."
    sudo apt update
    sudo apt install -y nginx git
else
    echo "Dependencies are already installed."
fi

# Clone the GitHub repository only if it doesn't exist
echo "Checking for the static website repository..."
if [ -d "$WEB_ROOT" ]; then
    echo "Repository already cloned at $WEB_ROOT. Skipping cloning."
else
    echo "Cloning the static website example repository..."
    sudo git clone "$STATIC_SITE_REPO" "$WEB_ROOT"
    sudo chown -R www-data:www-data "$WEB_ROOT"
    sudo chmod -R 755 "$WEB_ROOT"
fi

# Remove the default Nginx configuration if it exists
echo "Checking and removing default Nginx configuration..."
if [ -f "$NGINX_DEFAULT_CONF" ]; then
    echo "Removing default Nginx configuration..."
    sudo rm -f "$NGINX_DEFAULT_CONF"
else
    echo "Default Nginx configuration already removed."
fi

# Create Nginx configuration if it doesn't already exist
echo "Checking for Nginx configuration..."
if [ -f "$NGINX_CONF" ]; then
    echo "Nginx configuration already exists at $NGINX_CONF. Skipping configuration."
else
    echo "Creating Nginx configuration..."
    sudo bash -c "cat > $NGINX_CONF" <<EOL
server {
    listen 80;
    server_name localhost;

    root $WEB_ROOT;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL
fi

# Enable the site only if not already enabled
echo "Checking if the site is enabled..."
if [ -L "$NGINX_ENABLED" ]; then
    echo "Site is already enabled."
else
    echo "Enabling the site..."
    sudo ln -sf "$NGINX_CONF" "$NGINX_ENABLED"
fi

# Test and reload Nginx only if configuration has changed
echo "Checking Nginx configuration and reloading if necessary..."
sudo nginx -t
if ! sudo systemctl is-active --quiet nginx; then
    echo "Starting Nginx..."
    sudo systemctl start nginx
else
    echo "Reloading Nginx..."
    sudo systemctl reload nginx
fi

# Output success message
echo "Nginx is now serving the static website from $WEB_ROOT."
echo -e "\e[35mYou can access it at http://$1\e[0m"

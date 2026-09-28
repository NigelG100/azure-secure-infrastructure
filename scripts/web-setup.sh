#!/bin/bash
set -e

# Install Nginx
apt-get update -y
apt-get install -y nginx

# Configure Nginx as the public reverse proxy
cat > /etc/nginx/sites-available/secure-azure-app <<'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

   location /api/ {
    proxy_pass http://10.20.2.4:5000/;

    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_connect_timeout 5s;
    proxy_read_timeout 30s;
}
}
NGINX

# Disable the default Nginx site
rm -f /etc/nginx/sites-enabled/default

# Enable the reverse-proxy configuration
ln -sf /etc/nginx/sites-available/secure-azure-app \
       /etc/nginx/sites-enabled/secure-azure-app

# Validate configuration before restarting
nginx -t

systemctl enable nginx
systemctl restart nginx

echo "Nginx reverse proxy configured successfully."
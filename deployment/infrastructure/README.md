# Infrastructure Configuration

This directory contains OpenTofu/Terraform configuration for managing the Dart Cloud Backend infrastructure on Cloudflare.

## Prerequisites

1. **OpenTofu/Terraform**: Install from [opentofu.org](https://opentofu.org/) or [terraform.io](https://www.terraform.io/)
2. **Cloudflare Account**: With a domain configured
3. **VPS Server**: With a public IP address

## Setup

### 1. Get Cloudflare Credentials

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Go to **My Profile** → **API Tokens**
3. Create a token with these permissions:
   - Zone:DNS:Edit
   - Zone:Zone Settings:Edit
   - Zone:Zone:Read

4. Get your Zone ID:
   - Go to your domain overview
   - Copy the Zone ID from the right sidebar

### 2. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
cloudflare_api_token = "your-api-token-here"
cloudflare_zone_id   = "your-zone-id-here"
domain_name          = "yourdomain.com"
vps_ip_address       = "your-vps-ip"
backend_subdomain    = "api"
```

### 3. Initialize and Apply

```bash
# Initialize OpenTofu
tofu init

# Or with Terraform
terraform init

# Preview changes
tofu plan

# Apply configuration
tofu apply
```

## What Gets Created

1. **DNS A Record**: `api.yourdomain.com` → Your VPS IP
2. **Wildcard Record**: `*.api.yourdomain.com` → Your VPS IP (for function-specific subdomains)
3. **SSL/TLS Settings**: Full SSL encryption, HTTPS enforcement
4. **Rate Limiting**: 100 requests per minute per IP
5. **Cache Rules**: API requests bypass cache

## VPS Setup

After applying the infrastructure, set up your VPS:

### 1. Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Dart SDK
sudo apt install apt-transport-https
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart_stable.list
sudo apt update
sudo apt install dart

# Install PostgreSQL
sudo apt install postgresql postgresql-contrib
```

### 2. Configure PostgreSQL

```bash
sudo -u postgres psql

CREATE DATABASE dart_cloud;
CREATE USER dart_cloud_user WITH PASSWORD 'your-secure-password';
GRANT ALL PRIVILEGES ON DATABASE dart_cloud TO dart_cloud_user;
\q
```

### 3. Deploy Backend

```bash
# Clone your repository
git clone <your-repo-url>
cd ContainerPub/dart_cloud_backend

# Install dependencies
dart pub get

# Create .env file
cat > .env << EOF
PORT=8080
DATABASE_URL=postgres://dart_cloud_user:your-secure-password@localhost:5432/dart_cloud
JWT_SECRET=$(openssl rand -hex 32)
FUNCTIONS_DIR=/var/dart_cloud/functions
EOF

# Create functions directory
sudo mkdir -p /var/dart_cloud/functions
sudo chown $USER:$USER /var/dart_cloud/functions

# Run database migrations
dart run bin/server.dart
```

### 4. Set Up Systemd Service

Create `/etc/systemd/system/dart-cloud-backend.service`:

```ini
[Unit]
Description=Dart Cloud Backend
After=network.target postgresql.service

[Service]
Type=simple
User=your-user
WorkingDirectory=/path/to/dart_cloud_backend
Environment="PATH=/usr/lib/dart/bin:$PATH"
ExecStart=/usr/lib/dart/bin/dart run bin/server.dart
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable dart-cloud-backend
sudo systemctl start dart-cloud-backend
sudo systemctl status dart-cloud-backend
```

### 5. Configure Nginx Reverse Proxy

Install Nginx:

```bash
sudo apt install nginx
```

Create `/etc/nginx/sites-available/dart-cloud`:

```nginx
server {
    listen 80;
    server_name api.yourdomain.com *.api.yourdomain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable and restart:

```bash
sudo ln -s /etc/nginx/sites-available/dart-cloud /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## Managing Infrastructure

### View Current State

```bash
tofu show
```

### Update Configuration

1. Modify `main.tf` or `terraform.tfvars`
2. Run `tofu plan` to preview changes
3. Run `tofu apply` to apply changes

### Destroy Infrastructure

```bash
tofu destroy
```

## Outputs

After applying, you'll see:

- **backend_url**: The full URL of your backend API
- **backend_record_id**: Cloudflare DNS record ID

## Troubleshooting

### DNS Not Resolving

```bash
# Check DNS propagation
dig api.yourdomain.com

# Verify Cloudflare record
tofu state show cloudflare_record.backend_api
```

### SSL Issues

- Ensure Cloudflare SSL mode is set to "Full"
- Check that Nginx is running on port 80
- Cloudflare will automatically provision SSL certificate

### Backend Not Accessible

```bash
# Check backend service
sudo systemctl status dart-cloud-backend

# Check logs
sudo journalctl -u dart-cloud-backend -f

# Check Nginx
sudo nginx -t
sudo systemctl status nginx
```

## Security Recommendations

1. **Firewall**: Configure UFW to only allow ports 80, 443, and SSH
   ```bash
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

2. **SSH**: Disable password authentication, use SSH keys only

3. **Database**: Ensure PostgreSQL only accepts local connections

4. **Secrets**: Never commit `.tfvars` or `.env` files to version control

5. **Monitoring**: Set up monitoring and alerting for your VPS

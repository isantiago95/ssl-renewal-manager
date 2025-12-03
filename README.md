# SSL Certificate Manager

Simple Docker-based SSL certificate renewal system using Let's Encrypt. Works with any domain and exports certificates for easy import into web servers, reverse proxies, or NAS systems like Synology DSM.

## 🎯 What This Does

- **Renews SSL certificates** for any domain using Let's Encrypt
- **Docker-based**: Isolated, reproducible certificate management
- **Domain-agnostic**: Works with any domain name (interactive input)
- **Local export**: Saves certificates to local `./certificates/` directory
- **DNS-01 challenge**: Works behind firewalls and NAT (manual DNS verification)
- **Multiple formats**: Standard `privkey.pem` and `fullchain.pem` files

## 📁 Project Structure

```
ssl-manager/
├── docker-compose.yaml        # Docker configuration
├── renew-ssl.sh              # Main renewal script
├── .gitignore                # Ignore sensitive files
├── certificates/             # Exported certificates (created automatically)
├── letsencrypt-config/       # Certificate storage (created automatically)
├── letsencrypt-lib/          # Certbot library data (created automatically)
└── logs/                     # Application logs (created automatically)
```

## 📋 Prerequisites

- **Docker** and **Docker Compose** installed
- **DNS management access** for your domain (to add TXT records)
- **Domain ownership** verification capability

## 🚀 Quick Setup

### 1. Clone the Repository

```bash
# Clone the repository
git clone https://github.com/your-username/ssl-manager.git
cd ssl-manager
```

### 2. Create Your First Certificate

Run the script with the `--first-cert` flag to create your initial certificate:

```bash
./renew-ssl.sh --first-cert
```

The script will interactively ask you for:

- **Domain name** (e.g., `example.com`) - supports wildcards
- **Email address** (for Let's Encrypt account registration)

**Important**: During this process, you'll need to add a DNS TXT record to your domain DNS registry to validate ownership. Follow the prompts carefully and wait for DNS propagation before continuing.

### 3. Verify Setup

```bash
# Check that certificates were created and exported,
# Replace "example_com" with your domain name switching the `dot` with `underscore`:
# example.com -> example_com
ls -la ./certificates/example_com/
```

You should see: `privkey.pem` and `fullchain.pem` ready for use!

## 🔄 Certificate Renewal

### Manual Renewal

```bash
# Interactive mode (will prompt for domain)
./renew-ssl.sh

# Or specify domain directly
./renew-ssl.sh example.com

# For first-time certificate creation
./renew-ssl.sh --first-cert
```

### Automated Renewal Setup

Set up a monthly cron job for automatic renewal:

```bash
# Edit crontab
crontab -e

# Add this line for monthly renewal on the 1st at 2 AM
# Replace /path/to/ssl-manager and example.com with your values
0 2 1 * * cd /path/to/ssl-manager && ./renew-ssl.sh example.com
```

## 📋 Certificate Usage

After successful renewal, certificates are exported to `./certificates/your_domain_com/`:

### Certificate Files

- **Private Key**: `privkey.pem`
- **Full Chain**: `fullchain.pem` (includes certificate + intermediate)

### Server Import Examples

#### Synology DSM

1. Download the cert files to your computer due to the DSM interface doesn't let you import files from the same synology system, only upload them from your computer.
2. Go to **DSM > Control Panel > Security > Certificate**
3. Click **Add > Import certificate**
4. Select the files from `path/to/your/downloaded/cert/files`:
   - **Private Key**: `privkey.pem`
   - **Certificate**: `fullchain.pem`

#### Nginx

```bash
# Copy certificates to nginx directory
sudo cp ./certificates/your_domain_com/fullchain.pem /etc/nginx/ssl/
sudo cp ./certificates/your_domain_com/privkey.pem /etc/nginx/ssl/

# Update nginx config
ssl_certificate /etc/nginx/ssl/fullchain.pem;
ssl_certificate_key /etc/nginx/ssl/privkey.pem;
```

#### Apache

```bash
# Copy certificates
sudo cp ./certificates/your_domain_com/fullchain.pem /etc/apache2/ssl/
sudo cp ./certificates/your_domain_com/privkey.pem /etc/apache2/ssl/

# Update apache config
SSLCertificateFile /etc/apache2/ssl/fullchain.pem
SSLCertificateKeyFile /etc/apache2/ssl/privkey.pem
```

## 🔧 Configuration

### Multiple Domains

The system supports multiple domains automatically. Each domain gets its own folder:

```
certificates/
├── example_com/
│   ├── privkey.pem
│   └── fullchain.pem
└── another_domain_org/
    ├── privkey.pem
    └── fullchain.pem
```

### Custom Certificate Directory

By default, certificates are exported to `./certificates/`. This keeps everything contained within the project directory and works on any system.

## 📊 Monitoring & Logs

Check renewal status:

```bash
# View export logs
cat ./logs/export.log

# Check exported certificates
ls -la ./certificates/your_domain_com/*.pem

# Verify certificate expiration
openssl x509 -in ./certificates/your_domain_com/fullchain.pem -noout -dates
```

## ⚠️ Important Notes

- **Manual DNS Challenge**: Renewals require manual DNS TXT record updates (cannot be fully automated)
- **Backup**: Always backup existing certificates before renewal
- **Docker Required**: Ensure Docker and Docker Compose are installed
- **Testing**: Test renewal process manually before setting up automation

## 🛠 Troubleshooting

### Certificate Not Found

```bash
# Check if certificates exist in Let's Encrypt directory
ls -la ./letsencrypt-config/live/your-domain.com/

# Check if certificates were exported
ls -la ./certificates/your_domain_com/
```

### Docker Issues

```bash
# Check container logs
docker logs certbot-renew
docker logs ssl-export
```

### Permission Issues

```bash
# Fix permissions
chmod 644 ./certificates/your_domain_com/*.pem
```

---

## 🚀 Quick Start Example

```bash
# Clone and setup
git clone https://github.com/your-username/ssl-manager.git
cd ssl-manager

# Create your first certificate (interactive)
./renew-ssl.sh --first-cert
# Enter your domain: example.com
# Enter your email: your-email@example.com
# Follow DNS TXT record instructions

# For renewals, just run:
./renew-ssl.sh example.com

# Your certificates are now in:
# ./certificates/example_com/privkey.pem
# ./certificates/example_com/fullchain.pem
```

---

**This Docker-based SSL certificate manager works with any domain and any server system that supports standard SSL certificate files.**

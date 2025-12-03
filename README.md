# SSL Certificate Manager

Simple Docker-based SSL certificate renewal system using Let's Encrypt. Originally created for Synology NAS systems that don't support automatic SSL renewal for custom domains, but the generated certificate files work with any web server (Nginx, Apache, IIS, etc.).

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
git clone https://github.com/isantiago95/ssl-renewal-manager ssl-manager
cd ssl-manager

# Make the script executable
chmod +x renew-ssl.sh
```

### 2. Create Your First Certificate

Run the script with the `--first-cert` flag to create your initial certificate:

```bash
./renew-ssl.sh --first-cert
```

The script will interactively ask you for:

- **Domain name** (e.g., `your-domain.com`) - supports wildcards
- **Email address** (for Let's Encrypt account registration)

**Important**: During this process, you'll need to add a DNS TXT record to your domain DNS registry to validate ownership. Follow the prompts carefully and wait for DNS propagation before continuing.

### 3. Verify Setup

```bash
# Check that certificates were created and exported,
# Replace "your_domain_com" with your domain name switching the `dot` with `underscore`:
# your-domain.com -> your_domain_com
ls -la ./certificates/your_domain_com/
```

You should see: `privkey.pem` and `fullchain.pem` ready for use!

## 🔄 Certificate Renewal

### Manual Renewal

```bash
# Interactive mode (will prompt for domain)
./renew-ssl.sh

# Or specify domain directly
./renew-ssl.sh your-domain.com

# For first-time certificate creation
./renew-ssl.sh --first-cert
```

## Automated Renewal Setup

### Option 1: Cron job (not tested)

Set up a monthly cron job for automatic renewal:

```bash
# Edit crontab
crontab -e

# Add this line for monthly renewal on the 1st at 2 AM
# Replace /volume1/docker/ssl-manager and your-domain.com with your actual path and domain
0 2 1 * * cd /volume1/docker/ssl-manager/renew-ssl.sh your-domain.com
```

### Option 2: Synology DSM Task Scheduler (Tested)

**Step 1: Create the Task**

Navigate to: DSM → Control Panel → Task Scheduler → Create → Scheduled Task → User-defined script

**Step 2: General Settings**

Configure the General tab:

- Task name: `SSL Certificate Auto Renewal`
- User: `root` or `your_user_name` (make sure the user has Docker permissions)
- Enabled: ✅ Check this box

**Step 3: Schedule Settings**

Configure the Schedule tab:

- Date: Run on the following date
- Repeat: Monthly
- Date: Select `1` (1st of every month)
- Time: `02:00` (2 AM - low traffic time)
- Frequency: Every month

**Step 4: Task Settings**

Configure the Task Settings tab:

- Send run details by email: ✅ (Optional - for email notifications)
- Email: Your email address
- Send run details only when the script terminates abnormally: ✅ (Recommended)

Add the following user-defined script:

```bash
#!/bin/bash
# Replace /volume1/docker/ssl-manager with your actual path (where you cloned this repo)
# Replace your-domain.com with your actual domain
cd /volume1/docker/ssl-manager/renew-ssl.sh your-domain.com
```

## 📁 Certificate Files Formats

After successful renewal, certificates are exported to `./certificates/your_domain_com/` in **multiple formats**:

### 🔑 Required Formats

- **`your-domain.key`** - Private Key (.key format)
- **`your-domain.crt`** - Certificate (.crt format)
- **`intermediate.crt`** - Intermediate Certificate Chain (.crt format)
- **`your-domain.ca-bundle`** - CA Bundle (same as intermediate, different naming)

### 📋 Standard PEM Formats

- **`privkey.pem`** - Private Key (PEM format)
- **`cert.pem`** - Certificate only (PEM format)
- **`chain.pem`** - Certificate chain/intermediate (PEM format)
- **`fullchain.pem`** - Full certificate chain (PEM format)

### 🔧 Additional Formats

- **`your-domain.der`** - Certificate (DER binary format)
- **`your-domain.key.der`** - Private Key (DER binary format)
- **`your-domain.p7b`** - Certificate chain (PKCS#7 format)
- **`your-domain.pfx`** - Certificate + Key bundle (PKCS#12 format, no password)

## Server Import Examples

### Synology DSM (Tested)

1. Download certificate files to your computer
2. Go to **DSM > Control Panel > Security > Certificate**
3. Click **Add > Import certificate**
4. Then we have 2 options:

   1. **Option 1 (recommended): Individual files**
      - **Private Key**: `your-domain.key`
      - **Certificate**: `your-domain.crt`
      - **Intermediate Certificate**: `your-domain.ca-bundle` (Optional, see note below)

   > Note: Intermediate certificate for Synology DSM is optional, but some services may require it, such as the VPN Server. (See [this post](https://community.synology.com/enu/forum/1/post/128099))

   ![dsm-import-files-image](images/dsm-import-ssl-files.png)

   2. **Option 2: Standard PEM format**
      1. - **Private Key**: `privkey.pem` or `your-domain.key`
      2. - **Certificate**: `fullchain.pem` or `your-domain.crt`
      3. - **Intermediate Certificate**: `your-domain.ca-bundle` (optional)

### Other Cloud Servers

The generated certificate files are compatible with most web servers and applications:

- **Nginx, Apache, IIS**: Use the appropriate combination of `.key`, `.crt`, and intermediate files
- **Load Balancers**: Typically use `.crt` + `.key` + `intermediate.crt`
- **Java Applications**: Use `.pfx` file or convert PEM files as needed
- **Docker/Kubernetes**: Use standard PEM files (`privkey.pem`, `fullchain.pem`)

**Note**: Server-specific configuration examples are not provided as they haven't been tested. Consult your server's SSL certificate installation documentation.

## ℹ️ Information

### Multiple Domains

The system supports multiple domains automatically. Each domain gets its own folder:

```
certificates/
├── your_domain_com/
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

# Verify certificate expiration (remember to use the domain with underscore name)
openssl x509 -in ./certificates/your_domain_com/fullchain.pem -noout -dates
```

## ⚠️ Important Notes

- **Project Origin**: This project was created specifically for Synology NAS systems that don't support automatic SSL renewal for custom domains. However, the generated certificate files are compatible with any web server (Nginx, Apache, IIS, etc.).

- **User Responsibility**: You are responsible for:

  - Properly copying certificate files to the correct paths based on your server configuration
  - Renewing certificates **before they expire** (Let's Encrypt certificates expire every 90 days)
  - Testing the renewal process before setting up automation

- **SSH Setup for NAS/Cloud Servers**: To smoothly manage SSL renewals on any cloud server or NAS system:

  1. Connect via SSH to your server/NAS
  2. Clone this project to a familiar path (e.g., `/volume1/docker/ssl-manager` for Synology)
  3. Ensure Docker and Docker Compose are installed and accessible

- **Manual DNS Challenge**: Renewals require manual DNS TXT record updates (cannot be fully automated)
- **Backup**: Always backup existing certificates before renewal

## 🛠 Troubleshooting

### Certificate Not Found

```bash
# Check if certificates exist in Let's Encrypt directory
ls -la ./letsencrypt-config/live/your-domain.com/

# Check if certificates were exported
ls -la ./certificates/your_domain_com/

# create new certificates using the --first-cert flag
./renew-ssl.sh --first-cert
```

### Permission Issues

```bash
# Fix permissions
chmod +x renew-ssl.sh
```

---

## 🚀 Quick Start Example

```bash
# Clone and setup
git clone https://github.com/isantiago95/ssl-renewal-manager
cd ssl-manager

# Make the script executable
chmod +x renew-ssl.sh

# Create your first certificate (interactive)
./renew-ssl.sh --first-cert
# Enter your domain: your-domain.com
# Enter your email: your-email@your-domain.com
# Follow DNS TXT record instructions

# For renewals, just run:
./renew-ssl.sh your-domain.com

# Your certificates are now in ALL formats:
# Required formats:
# ./certificates/your_domain_com/your-domain.com.key
# ./certificates/your_domain_com/your-domain.com.crt
# ./certificates/your_domain_com/intermediate.crt
# ./certificates/your_domain_com/your-domain.com.ca-bundle
#
# Plus: .pem, .der, .p7b, .pfx formats for maximum compatibility
```

---

**This Docker-based SSL certificate manager works with any domain and any server system that supports standard SSL certificate files.**

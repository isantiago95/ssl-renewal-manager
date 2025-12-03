#!/bin/bash

# Get current directory (should be the ssl-manager project root)
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo "======================================================"
echo "SSL Certificate Renewal Process"
echo "======================================================"
echo "Time: $(date)"
echo "Location: $(pwd)"
echo ""

# Ask for domain name
if [ -z "$1" ]; then
    echo "🌐 Enter the domain name for SSL certificate renewal:"
    read -p "Domain (e.g., example.com): " DOMAIN_NAME
else
    DOMAIN_NAME="$1"
fi

if [ -z "$DOMAIN_NAME" ]; then
    echo "❌ ERROR: Domain name is required!"
    exit 1
fi

# Convert domain to safe folder name (replace dots with underscores)
DOMAIN_FOLDER=$(echo "$DOMAIN_NAME" | sed 's/\./_/g')

echo "📋 Configuration:"
echo "   Domain: $DOMAIN_NAME"
echo "   Output folder: certificates/$DOMAIN_FOLDER/"
echo ""

# Create certificates directory if it doesn't exist
mkdir -p "$PROJECT_DIR/certificates/$DOMAIN_FOLDER"

# Check if compose file exists
if [ ! -f "docker-compose.yaml" ]; then
    echo "❌ ERROR: docker-compose.yml not found in $(pwd)"
    exit 1
fi

echo "🔄 Starting Docker containers for SSL renewal..."
echo ""

# Export environment variables for docker-compose
export DOMAIN_NAME
export DOMAIN_FOLDER

# Run docker-compose and capture ALL output
docker-compose up 2>&1

# Capture the exit code
DOCKER_EXIT_CODE=$?

echo ""
echo "======================================================"
echo "Docker Process Completed"
echo "======================================================"
echo "Docker exit code: $DOCKER_EXIT_CODE"
echo ""

# Show detailed container logs
echo "📋 Container Logs:"
echo "------------------------------------------------------"
echo ""
echo "=== Certbot Container Logs ==="
docker logs certbot-renew 2>&1 || echo "No certbot-renew logs available"

echo ""
echo "=== SSL Export Container Logs ==="
docker logs ssl-export 2>&1 || echo "No ssl-export logs available"

echo ""
echo "======================================================"
echo "Certificate Status Check"
echo "======================================================"

# Check for exported certificate files
CERT_FOLDER="$PROJECT_DIR/certificates/$DOMAIN_FOLDER"
echo "Checking for certificates in: $CERT_FOLDER"
echo ""

if [ -f "$CERT_FOLDER/privkey.pem" ] && [ -f "$CERT_FOLDER/fullchain.pem" ]; then
    echo "✅ SUCCESS: Certificate files found and ready for import!"
    echo ""
    echo "📁 Certificate Files for $DOMAIN_NAME:"
    echo "  Private Key: privkey.pem"
    echo "  Full Chain: fullchain.pem (certificate + intermediate)"
    echo ""
    ls -la "$CERT_FOLDER"/*.pem 2>/dev/null
    echo ""
    
    # Show certificate details
    echo "🔍 Certificate Details:"
    openssl x509 -in "$CERT_FOLDER/fullchain.pem" -noout -subject -issuer -dates 2>/dev/null || echo "Could not read certificate details"
    
else
    echo "❌ FAILURE: Certificate files not found"
    echo ""
    echo "📁 Directory contents:"
    ls -la "$CERT_DIR"/ 2>/dev/null
    echo ""
    
    # Show more detailed error logs
    echo "🔍 Detailed Error Investigation:"
    echo ""
    echo "Certbot config directory:"
    ls -la ./letsencrypt-config/live/ 2>/dev/null || echo "No live certificates directory"
    
    echo ""
    echo "Recent certbot logs:"
    find ./logs -name "*.log" -type f -exec tail -5 {} \; 2>/dev/null || echo "No log files found"
fi

echo ""
echo "======================================================"
echo "Process Summary"
echo "======================================================"
echo "End time: $(date)"

if [ -f "$CERT_FOLDER/privkey.pem" ] && [ -f "$CERT_FOLDER/fullchain.pem" ]; then
    echo "📧 RESULT: SUCCESS - New SSL certificates are ready for $DOMAIN_NAME"
    echo "   → Certificate files in certificates/$DOMAIN_FOLDER/:"
    echo "     • Private Key: privkey.pem"
    echo "     • Full Chain: fullchain.pem (includes certificate + intermediate)"
    echo "   → Files location: $CERT_FOLDER"
    echo "   → Import via your server's SSL certificate management interface"
else
    echo "📧 RESULT: FAILED - SSL certificate renewal unsuccessful"
    echo "   → Check the logs above for error details"
    echo "   → The certificates exist, but export failed"
    echo "   → Try running: DOMAIN_NAME=$DOMAIN_NAME DOMAIN_FOLDER=$DOMAIN_FOLDER docker-compose up ssl-export"
fi

echo "======================================================"

# Clean up containers
echo ""
echo "🧹 Cleaning up containers..."
docker-compose down 2>/dev/null

exit $DOCKER_EXIT_CODE

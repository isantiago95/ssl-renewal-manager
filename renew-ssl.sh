#!/bin/bash

# Get current directory (should be the ssl-manager project root)
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

# Check for --first-cert flag
FIRST_CERT_MODE=false
if [ "$1" = "--first-cert" ]; then
    FIRST_CERT_MODE=true
    shift # Remove the flag from arguments
fi

if [ "$FIRST_CERT_MODE" = true ]; then
    echo "======================================================"
    echo "SSL Certificate Initial Creation"
    echo "======================================================"
else
    echo "======================================================"
    echo "SSL Certificate Renewal Process"
    echo "======================================================"
fi

echo "Time: $(date)"
echo "Location: $(pwd)"
echo ""

# Handle domain name input
if [ "$FIRST_CERT_MODE" = true ]; then
    # First certificate mode - always ask for domain and email
    echo "🌐 Enter the domain name for SSL certificate creation:"
    read -p "Domain (e.g., example.com): " DOMAIN_NAME
    
    echo "📧 Enter your email address for Let's Encrypt account:"
    read -p "Email: " EMAIL_ADDRESS
    
    if [ -z "$DOMAIN_NAME" ] || [ -z "$EMAIL_ADDRESS" ]; then
        echo "❌ ERROR: Both domain name and email are required!"
        exit 1
    fi
else
    # Renewal mode - ask for domain or use argument
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
fi

# Convert domain to safe folder name (replace dots with underscores)
DOMAIN_FOLDER=$(echo "$DOMAIN_NAME" | sed 's/\./_/g')

echo "📋 Configuration:"
echo "   Domain: $DOMAIN_NAME"
if [ "$FIRST_CERT_MODE" = true ]; then
    echo "   Email: $EMAIL_ADDRESS"
fi
echo "   Output folder: certificates/$DOMAIN_FOLDER/"
echo ""

# Create required directories
mkdir -p "$PROJECT_DIR/certificates/$DOMAIN_FOLDER"
mkdir -p "$PROJECT_DIR/letsencrypt-config"
mkdir -p "$PROJECT_DIR/letsencrypt-lib" 
mkdir -p "$PROJECT_DIR/logs"

if [ "$FIRST_CERT_MODE" = true ]; then
    echo "🆕 Creating initial SSL certificate..."
    echo "📝 Note: You will need to add a DNS TXT record during this process"
    echo ""
    
    # Create initial certificate using certbot directly
    docker run -it --rm \
        -v "$PROJECT_DIR/letsencrypt-config:/etc/letsencrypt" \
        -v "$PROJECT_DIR/letsencrypt-lib:/var/lib/letsencrypt" \
        certbot/certbot certonly -v --manual --preferred-challenges dns \
        -d "$DOMAIN_NAME" -d "*.$DOMAIN_NAME" \
        --agree-tos --email "$EMAIL_ADDRESS"
    
    CERTBOT_EXIT_CODE=$?
    
    if [ $CERTBOT_EXIT_CODE -eq 0 ]; then
        echo ""
        echo "✅ Initial certificate created successfully!"
        echo "🔄 Now exporting certificate files..."
        echo ""
    else
        echo ""
        echo "❌ Failed to create initial certificate"
        echo "   → Please check the error messages above"
        echo "   → Ensure you added the DNS TXT record correctly"
        exit 1
    fi
fi

# Check if compose file exists
if [ ! -f "docker-compose.yaml" ]; then
    echo "❌ ERROR: docker-compose.yaml not found in $(pwd)"
    exit 1
fi

if [ "$FIRST_CERT_MODE" = true ]; then
    echo "📦 Exporting certificates..."
else
    echo "🔄 Starting Docker containers for SSL renewal..."
fi
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

# Check for required certificate formats
REQUIRED_KEY="$CERT_FOLDER/$DOMAIN_NAME.key"
REQUIRED_CRT="$CERT_FOLDER/$DOMAIN_NAME.crt"
REQUIRED_INT="$CERT_FOLDER/intermediate.crt"

if [ -f "$REQUIRED_KEY" ] && [ -f "$REQUIRED_CRT" ] && [ -f "$REQUIRED_INT" ]; then
    echo "✅ SUCCESS: All certificate files generated and ready for use!"
    echo ""
    echo "🔑 REQUIRED FORMATS (ready to use):"
    echo "  - $DOMAIN_NAME.key (Private Key)"
    echo "  - $DOMAIN_NAME.crt (Certificate)" 
    echo "  - intermediate.crt (Intermediate Certificate)"
    echo ""
    echo "📋 ALL GENERATED FORMATS:"
    ls -la "$CERT_FOLDER"/ 2>/dev/null
    echo ""
    
    # Show certificate details
    echo "🔍 Certificate Details:"
    openssl x509 -in "$REQUIRED_CRT" -noout -subject -issuer -dates 2>/dev/null || echo "Could not read certificate details"
    
else
    echo "❌ FAILURE: Required certificate files not found"
    echo ""
    echo "📁 Expected files:"
    echo "  - $DOMAIN_NAME.key (Private Key)"
    echo "  - $DOMAIN_NAME.crt (Certificate)"
    echo "  - intermediate.crt (Intermediate Certificate)"
    echo ""
    echo "📁 Directory contents:"
    ls -la "$CERT_FOLDER"/ 2>/dev/null || echo "Directory does not exist"
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

if [ -f "$REQUIRED_KEY" ] && [ -f "$REQUIRED_CRT" ] && [ -f "$REQUIRED_INT" ]; then
    if [ "$FIRST_CERT_MODE" = true ]; then
        echo "📧 RESULT: SUCCESS - Initial SSL certificates created and exported!"
        echo "   → Your SSL certificates for $DOMAIN_NAME are ready in ALL formats"
        echo "   → Set up automatic renewal with: ./renew-ssl.sh $DOMAIN_NAME"
    else
        echo "📧 RESULT: SUCCESS - SSL certificates renewed for $DOMAIN_NAME"
    fi
    echo ""
    echo "🔑 REQUIRED FORMATS:"
    echo "   → $DOMAIN_NAME.key (Private Key)"
    echo "   → $DOMAIN_NAME.crt (Certificate)"
    echo "   → intermediate.crt (Intermediate Certificate)"
    echo ""
    echo "📋 ALL FORMATS AVAILABLE:"
    echo "   → Standard: .pem files (privkey, cert, chain, fullchain)"
    echo "   → Binary: .der files (certificate and key)"
    echo "   → PKCS#7: .p7b file (certificate chain)"
    echo "   → PKCS#12: .pfx file (certificate + key bundle)"
    echo ""
    echo "📁 Files location: $CERT_FOLDER"
else
    if [ "$FIRST_CERT_MODE" = true ]; then
        echo "📧 RESULT: FAILED - Initial certificate creation unsuccessful"
        echo "   → The certificate may have been created but export failed"
        echo "   → Check: ls -la ./letsencrypt-config/live/$DOMAIN_NAME/"
        echo "   → If certificates exist, try: ./renew-ssl.sh $DOMAIN_NAME"
    else
        echo "📧 RESULT: FAILED - SSL certificate renewal unsuccessful"
        echo "   → Check the logs above for error details"
        echo "   → The certificates exist, but export failed"
        echo "   → Try running: DOMAIN_NAME=$DOMAIN_NAME DOMAIN_FOLDER=$DOMAIN_FOLDER docker-compose up ssl-export"
    fi
fi

echo "======================================================"

# Clean up containers
echo ""
echo "🧹 Cleaning up containers..."
docker-compose down 2>/dev/null

exit $DOCKER_EXIT_CODE

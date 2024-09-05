#!/bin/bash

# Create a subfolder to store OCSP responses
mkdir -p ocsp_responses

# Function to get the certificate and check OCSP
check_ocsp() {
    DOMAIN=$1
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    OUTPUT_FOLDER="ocsp_responses/$DOMAIN"

    # Create a folder for the domain if it doesn't exist
    mkdir -p $OUTPUT_FOLDER

    echo "Processing domain: $DOMAIN at $TIMESTAMP" | tee -a ocsp_log.txt

    # Get the certificate
    openssl s_client -connect $DOMAIN:443 2>&1 < /dev/null | sed -n '/-----BEGIN/,/-----END/p' > cert.pem

    # Check if the certificate has an OCSP URI
    OCSP_URI=$(openssl x509 -noout -ocsp_uri -in cert.pem)

    if [ -z "$OCSP_URI" ]; then
        echo "No OCSP URI found for $DOMAIN" | tee -a ocsp_log.txt
        return
    fi

    echo "OCSP URI found: $OCSP_URI" | tee -a ocsp_log.txt

    # Get the certificate chain
    openssl s_client -connect $DOMAIN:443 -showcerts 2>&1 < /dev/null | awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/{print $0}' > chain.pem

    # Extract only the second certificate
    awk '/-----BEGIN CERTIFICATE-----/{n++} n==2 {print}' chain.pem > issuer.pem

    # Send OCSP request using the second certificate as the issuer
    RESPONSE=$(openssl ocsp -issuer issuer.pem -cert cert.pem -text -url $OCSP_URI)

    # Save the OCSP response to a file
    RESPONSE_FILE="$OUTPUT_FOLDER/ocsp_response_$TIMESTAMP.txt"
    echo "$RESPONSE" > $RESPONSE_FILE

    # Extract and display the "Produced At" timestamp
    PRODUCED_AT=$(echo "$RESPONSE" | grep -i "Produced At")
    echo "$PRODUCED_AT" | tee -a ocsp_log.txt

    echo "OCSP response saved to $RESPONSE_FILE" | tee -a ocsp_log.txt
    echo "-------------------------------------" | tee -a ocsp_log.txt

    # Clean up
    rm cert.pem chain.pem issuer.pem
}

# List of domains to check
DOMAINS=("wikipedia.org" "gstatic.com" "google.com" "yahoo.com" "facebook.com" "twitter.com" "linkedin.com" "apple.com" "microsoft.com" "amazon.com" "icloud.com" "instagram.com")

# Run the script for 24 hours, fetching responses every 30 minutes
END_TIME=$((SECONDS + 86400))  # 86400 seconds = 24 hours

while [ $SECONDS -lt $END_TIME ]; do
    for DOMAIN in "${DOMAINS[@]}"; do
        check_ocsp $DOMAIN
    done
    echo "Sleeping for 30 minutes..." | tee -a ocsp_log.txt
    sleep 1800  # 1800 seconds = 30 minutes
done

echo "OCSP check completed after 24 hours. Results are logged in ocsp_log.txt"

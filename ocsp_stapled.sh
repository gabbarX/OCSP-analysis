#!/bin/bash

# Create a subfolder to store OCSP responses
mkdir -p ocsp_responses

# Function to get the certificate and check OCSP
check_ocsp() {
    DOMAIN=$1
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    OUTPUT_FOLDER="stapled_ocsp_responses/$DOMAIN"

    # Create a folder for the domain if it doesn't exist
    mkdir -p $OUTPUT_FOLDER

    echo "Processing domain: $DOMAIN at $TIMESTAMP" | tee -a ocsp_log.txt

    # Get the certificate and stapled OCSP response from the server
    OPENSSL_OUTPUT=$(openssl s_client -connect $DOMAIN:443 -status 2>&1 < /dev/null)

    # Extract the stapled OCSP response if available
    STAPLED_OCSP=$(echo "$OPENSSL_OUTPUT" | sed -n '/OCSP Response Data:/,/---/p')

    if [ -n "$STAPLED_OCSP" ]; then
        echo "Stapled OCSP response found for $DOMAIN" | tee -a ocsp_log.txt

        # Extract the "Produced At" field from the stapled OCSP response
        PRODUCED_AT=$(echo "$STAPLED_OCSP" | grep -i "Produced At")
        echo "$PRODUCED_AT" | tee -a ocsp_log.txt

        # Save the stapled OCSP response to a file
        STAPLED_RESPONSE_FILE="$OUTPUT_FOLDER/stapled_ocsp_response_$TIMESTAMP.txt"
        echo "$STAPLED_OCSP" > "$STAPLED_RESPONSE_FILE"

        echo "Stapled OCSP response saved to $STAPLED_RESPONSE_FILE" | tee -a ocsp_log.txt
        echo "-------------------------------------" | tee -a ocsp_log.txt
    else
        echo "No stapled OCSP response found for $DOMAIN, proceeding with regular OCSP check." | tee -a ocsp_log.txt

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
    fi
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

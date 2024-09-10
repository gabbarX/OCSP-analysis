#!/bin/bash

# Create a subfolder to store OCSP responses
mkdir -p ocsp_responses

# Function to get the stapled OCSP response from the server
check_ocsp() {
    DOMAIN=$1
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    OUTPUT_FOLDER="ocsp_responses/$DOMAIN"

    # Create a folder for the domain if it doesn't exist
    mkdir -p $OUTPUT_FOLDER

    echo "Processing domain: $DOMAIN at $TIMESTAMP" | tee -a ocsp_log.txt

    # Get the certificate and stapled OCSP response from the server
    OPENSSL_OUTPUT=$(openssl s_client -connect $DOMAIN:443 -status 2>&1 < /dev/null)

    # Check if the OCSP response is available in the output
    if echo "$OPENSSL_OUTPUT" | grep -q "OCSP Response Status:"; then
        echo "Stapled OCSP response found for $DOMAIN" | tee -a ocsp_log.txt

        # Extract the OCSP response block
        STAPLED_OCSP=$(echo "$OPENSSL_OUTPUT" | sed -n '/OCSP Response Data:/,/---/p')

        # Extract the "Produced At" field from the stapled OCSP response
        PRODUCED_AT=$(echo "$STAPLED_OCSP" | grep -i "Produced At")
        echo "$PRODUCED_AT" | tee -a ocsp_log.txt

        # Save the stapled OCSP response to a file
        STAPLED_RESPONSE_FILE="$OUTPUT_FOLDER/stapled_ocsp_response_$TIMESTAMP.txt"
        echo "$STAPLED_OCSP" > "$STAPLED_RESPONSE_FILE"

        echo "Stapled OCSP response saved to $STAPLED_RESPONSE_FILE" | tee -a ocsp_log.txt
    else
        echo "No stapled OCSP response found for $DOMAIN" | tee -a ocsp_log.txt
    fi

    echo "-------------------------------------" | tee -a ocsp_log.txt
}

# List of domains to check
DOMAINS=("wikipedia.org" "unity3d.com" "fastly.net" "yahoo.com" "casalemedia.com" "roblox.com" "linkedin.com" "apple.com" "www.microsoft.com" "amazon.com" "icloud.com" "fastcompany.com")

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

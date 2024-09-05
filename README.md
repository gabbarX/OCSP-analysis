# OCSP Checker

## Overview

This Bash script performs an Online Certificate Status Protocol (OCSP) check for a list of domains. It fetches the current certificates from each domain, verifies their status using the OCSP URI provided in the certificate, and logs the results. The script runs continuously for 24 hours, fetching responses every 30 minutes.

## Features

- **Fetches Certificates:** Retrieves the current certificate from each domain using OpenSSL.
- **Checks OCSP Status:** Queries the OCSP server specified in the certificate to determine its status.
- **Logs Results:** Saves the OCSP responses and their "Produced At" timestamps to log files.
- **Handles Multiple Domains:** Can be configured to check multiple domains in a single run.
- **Scheduled Execution:** Runs continuously for 24 hours, with checks every 30 minutes.

## Usage

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/yourusername/ocsp-checker.git
   cd ocsp-checker
   ```
2. **Make the Script Executable:**
   ```bash
   chmod +x check_ocsp.sh
   ```
3. **Run the Script:**
   ```bash
   ./check_ocsp.sh
   ```
  The script will start processing the domains listed in the script and will run for 24 hours, performing checks every 30 minutes.

## Script Details

### Directory Structure

- **`ocsp_responses/`**: Directory where OCSP responses are stored.
- **`ocsp_log.txt`**: Log file containing the timestamps and status of each OCSP response.

### Functionality

- **`check_ocsp` Function**: Handles fetching the certificate, checking OCSP status, and logging results.
- **Domain List**: You can customize the list of domains in the `DOMAINS` array within the script.
- **Execution Time**: The script runs for 24 hours and performs checks every 30 minutes.

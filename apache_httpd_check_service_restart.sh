#!/usr/bin/env bash

########################################################

#PROD Apache (HTTPD) Service Check & Restarts

########################################################
 
# --- Configurations & Variables ---
BASE_DIR="$HOME/cxp_expnw_menu_jumpserver/servicechecks/apache-httpd/prod"
INV_DIR="$BASE_DIR/inventory"
TEMP_DIR="$BASE_DIR/temp"
HISTORY_FILE="$BASE_DIR/log/apache-httpd-prod-servicechecks-run-history"

# --- Inputs/Outputs ---
ap_server_list="$INV_DIR/prod-server-list.txt"
mail_report="$TEMP_DIR/failed-expnw-prod-apache-httpd-report.txt"

# --- Style ---
BGREEN='\e[92m'
RED='\e[31m'
NC='\e[0m' # No Color

# --- Initialization ---
mkdir -p "$TEMP_DIR"
> "$mail_report"

# --- Clean up history if file size > 3 units ---
find "$BASE_DIR" -type f -name "apache-httpd-prod-servicechecks-run-history" -size +3 -exec truncate -s 0 {} +

# --- Log execution ---
{
    date | tr '\n' ' '
    pgrep -f "apache-httpd-prod" || echo "No active apache-httpd-prod process"
} >> "$HISTORY_FILE"

# --- Main Logic ---
echo -e "\n${BGREEN}Checking Apache (HTTPD) status on production servers...${NC}\n"

# Use one loop to handle connectivity and status checks to save SSH overhead
# Servers are stored where Apache (HTTPD) is found to be down in the servers_to_restart array.

servers_to_restart=()
 
for server in $(<"$ap_server_list"); do
    # Run the check
    PID=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 -o LogLevel=error "chq-reinogar@$server" \
        "pgrep -f /bin/httpd -o")

    status=$?

    if [ $status -eq 0 ]; then
        echo -e "${BGREEN}OK${NC}: $server"
        echo
    elif [ $status -eq 255 ]; then
        # SSH failed (Connection/Auth error) - Do NOT add to restart list
        echo "SSH ERROR: Could not connect to $server"
        echo
    else
        # SSH worked, but pgrep failed (Apache (HTTPD) is DOWN)
        echo -e "${RED}DOWN${NC}: $server"
        servers_to_restart+=("$server")
        echo
    fi
done

# --- Remediation ---
if [ ${#servers_to_restart[@]} -eq 0 ]; then
    echo -e "${BGREEN}Apache (HTTPD) is running on all production servers!${NC}"
    exit 0
fi

echo -e "\n${BGREEN}Restarting Apache (HTTPD) on failed servers...${NC}\n"

for target in "${servers_to_restart[@]}"; do
    # Restart and immediately verify PID in one SSH session
    new_pid=$(ssh -o StrictHostKeyChecking=no -o LogLevel=error -o ConnectTimeout=3 "chq-reinogar@$target" \
        "sudo systemctl restart httpd > /dev/null 2>&1; pgrep -f /bin/httpd -o")

    if [ -n "$new_pid" ]; then
        echo "apache (httpd) was restarted on $target (PID=$new_pid)" >> "$mail_report"
    fi
done

sed -e 's/^/\r/' -e '/^[[:space:]]*$/d' "$mail_report"

# --- Email Notification ---

mail -s "APACHE-HTTPD-SERVICES-DOWN-BUT-RESTARTED" \
     -a "$mail_report" \
     -r "servicemon@abc.com" \
     "tigerteam@abc.com blackpanther@abc.com" <<EOD

Attached is a list of PROD APACHE (HTTPD) Services that were DOWN but RESTARTED!
*************************************************************************
EOD
echo -e "\nEmail sent with $(wc -l < "$mail_report") updates."

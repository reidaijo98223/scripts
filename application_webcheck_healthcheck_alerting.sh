#!/usr/bin/env bash

################################################################################
# PROD Server Webcheck
# 
# Description: This script issues a curl command for specified URLs. If a 
# status of 200 is returned and specific webcheck output matches, the service
# is marked available. Otherwise, it logs a failure.
################################################################################

# --- ACTION REQUIRED: Update Variables ---
APPNAME="REPLACE-WITH-APPNAME"                           # Display purposes, must be ALL CAPS (e.g. PLATEFORMAPI)
APPNAME2="replace-with-appname"                          # File paths, must be lowercase (e.g. plateformapi)
APP_SERVICE_ACCOUNT_USER="replace-with-service-accounts" # Service account names (gqlrouterin, kongint)
DEV_TEAM="replace-with-owning-team"                      # Owner Dev Team (e.g. Windsocke)
WEBCHECK_PHRASE="replace-with-webecheck-phrase1"         # Regex pattern for primary check (e.g. auth0.*Available)
WEBCHECK_PHRASE2="replace-with-webcheck-phrase2"         # Regex pattern for secondary check (e.g. EXP NOW)
SEND_TO="replace-with-email-recipients"                  # Email address of recipients (e.g. windsocke@abc.com)

# --- Configurations & Variables ---
BASE_PATH="$HOME/cxp_expnow_menu_jumpserver/webchecks/$APPNAME2/prod"
TEMP_DIR="$BASE_PATH/temp"
URL_LIST="$HOME/cxp_expnow_menu_jumpserver/webchecks/urls/$APPNAME2-url.txt"
URL_LIST2="$HOME/cxp_expnow_menu_jumpserver/webchecks/urls/$APPNAME2-vip-url.txt"
HISTORY_FILE="$BASE_PATH/log/$APPNAME2-webchecks-run-history"
MAIL_FILE="$TEMP_DIR/failed-exponow-webchecks.txt"

ENDPOINT="https://abc.webhook.office.com/webhookb2/edb80fc3-ac01-4eba-99ce-0fdaf15374@fe74e8-131d-4caa-be5c-31e128506c40/IncomingWebhook/6db1d7de-a381-4939-ae22-b53943db0a/V2TJVVMZed0bOAMew_-DkzGbMDyTbAx-ZXw1"
CONTACT_INFO="https://abc.sharepoint.com/sites/ABC/SitePages/Prod%Support.aspx"

# --- Style ---
BGREEN="\033[92m"
RED="\033[31;40m"
ULINE="\033[4m"
NONE="\033[0m"

# --- Initialization ---
mkdir -p "$TEMP_DIR" "$(dirname "$HISTORY_FILE")"
> "$MAIL_FILE"

# --- Clean up history if file size > 3 Megabytes ---
find "$BASE_PATH" -type f -name "*-run-history" -size +3M -exec truncate -s 0 {} +

# --- Log execution ---
{
    date | tr '\n' ' '
    pgrep -f "$APPNAME2-prod" || echo "No active $APPNAME2-prod process"
} >> "$HISTORY_FILE"

# --- Email & Teams Alert Function ---
send_alerts() {
    # Send Email Alert
    mail -s "Failed-EXPONOW-PRODUCTION-Webchecks-$APPNAME" \
         -r "servicemon@abc.com" \
         -c "tigerteam@abc.com blackpanther@abc.com" \
         "$SEND_TO" <<EOD
List of $APPNAME Webchecks that are Down! (3 hits in the last 15 minutes)!!!
************************************************
$(cat "$MAIL_FILE")

Support Contact Info: $CONTACT_INFO
EOD

    echo -e "\nEmail Alert Sent Successfully!"

    # Format mail file payload safely for MS Teams Message Card
    local x
    x=$(echo -e "\r\n\r\n**List of $APPNAME Webchecks that are Down! (3 hits in the last 15 minutes)!!!**\n$(cat "$MAIL_FILE")\nSupport Contact Info: $CONTACT_INFO")
    echo "$x" > "$MAIL_FILE"
    
    sleep 1
    sed -i -e '2 s/^/****/;s/$/\\n/' "$MAIL_FILE"
    
    local mailFile2
    mailFile2=$(cat "$MAIL_FILE")
    
    local DATA
    DATA="{\"@context\": \"http://schema.org/extensions\",\"@type\": \"MessageCard\",\"text\": \"$mailFile2\"}"
    
    export HTTP_PROXY=http://proxy.abc.ei:8080
    export HTTPS_PROXY=http://proxy.abc.ei:8080
    export NO_PROXY=*.office.com
    
    curl -XPOST -H 'Content-type: application/json' -d "$DATA" "$ENDPOINT"
    echo -e "\nAlert was Sent to TEAMS Webhook Successfully!"
}

# --- Email Recovery Alert Function ---
send_recovery_alert() {
    local server="$1"
    local url="$2"
   
    mail -s "RECOVERED: $APPNAME-PRODUCTION-Webcheck-Healthy" \
         -r "cxpmone@abc.com" \
         -c "tigerteam@abc.com blackpanther@abc.com" \
         "$SEND_TO" <<EOD
The following webcheck is now HEALTHY:
************************************************
Server: $server
URL: $url

Application: $APP_SERVICE_ACCOUNT_USER
EOD

    echo -e "${BGREEN}Recovery Alert Sent for $server${NONE}"
}

# --- Main Logic ---
echo -e "\n${ULINE}PROD $APPNAME SERVER WEBCHECK${NONE}\n"

# Verify inputs exist
if [ ! -f "$URL_LIST" ] || [ ! -f "$URL_LIST2" ]; then
    echo "ERROR: One or more URL specification lists are missing."
    exit 1
fi

# Define the pairs: "URL_FILE|PHRASE"
tasks=(
    "$URL_LIST|$WEBCHECK_PHRASE"
    "$URL_LIST2|$WEBCHECK_PHRASE2"
)

for task in "${tasks[@]}"; do
    current_file="${task%%|*}"
    current_phrase="${task##*|}"

    # Read one line at a time from the url text file
    while IFS= read -r urlfile || [[ -n "$urlfile" ]]; do
        # Loop through each individual URL in the string line
        for url in $urlfile; do
            # Extract server name safely to construct system flags
            server_name=$(echo "$url" | cut -d ":" -f2 | cut -d "/" -f3)
            INDIVIDUAL_COUNT="$TEMP_DIR/count_${server_name}.txt"
            STATUS_FILE="$TEMP_DIR/${server_name}.status"

            # Grab the website payload content and trailing status code
            response=$(curl -sL --insecure --max-time 7 -w "%{http_code}" "$url" </dev/null)
            http_code="${response: -3}"
            body="${response::-3}"

            # Flag to track loop-level verification status
            failed=0

            # Check HTTP Status and Body Content
            if [[ "$http_code" != "200" ]]; then
                echo -e "${RED}$url is down ($http_code)${NONE}"
                failed=1
            elif [[ ! "$body" =~ $current_phrase ]]; then
                echo -e "${RED}$url verification failed${NONE}"
                failed=1
            else
                echo -e "${BGREEN}$url is available (200 & verified)${NONE}"
                
                # Recovery Trigger: If it was broken, notify recovery and wipe down state
                if [[ -f "$STATUS_FILE" ]]; then
                    send_recovery_alert "$server_name" "$url"
                    rm -f "$STATUS_FILE" "$INDIVIDUAL_COUNT"
                fi
            fi

            # Individualized Counter & Alert Logic
            if [[ "$failed" -eq 1 ]]; then
                server_var="marked_${server_name//[^a-zA-Z0-9]/_}"

                if [[ "${!server_var}" != "yes" ]]; then
                    [[ ! -f "$INDIVIDUAL_COUNT" ]] && touch "$INDIVIDUAL_COUNT" && touch -d "10 minutes ago" "$INDIVIDUAL_COUNT"

                    # Check age of count file (Reset if > 7 mins since previous hit)
                    last_mod=$(stat -c %Y "$INDIVIDUAL_COUNT")
                    if (( ($(date +%s) - last_mod) > 420 )); then
                        truncate -s 0 "$INDIVIDUAL_COUNT"
                    fi

                    # Log hit metric tracking item
                    echo -n "I" >> "$INDIVIDUAL_COUNT"
                    touch "$INDIVIDUAL_COUNT"
                  
                    eval "$server_var='yes'"
                fi

                current_count=$(wc -c < "$INDIVIDUAL_COUNT")

                # Alert if 3 consecutive failures hit without a recovery step
                if [[ "$current_count" -ge 3 ]] && [[ ! -f "$STATUS_FILE" ]]; then
                    echo -e "$server_name" > "$MAIL_FILE"
                    echo -e "$APPNAME2 webcheck failed ($APP_SERVICE_ACCOUNT_USER): $url. Inform the $DEV_TEAM on-call contact.\n" >> "$MAIL_FILE"
                    
                    # Touch status tracker file to prevent spamming updates
                    touch "$STATUS_FILE"
                    send_alerts
                fi
            fi
        done
    done < "$current_file"
done

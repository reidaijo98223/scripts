#!/usr/bin/env bash

##################################################################################
# PROD Elastic Beats (Metricbeat, Filebeat, Heartbeat) Service Check & Restarts
##################################################################################

# --- Configuration & Variables ---
BASE_DIR="$HOME/cxp_exponow_menu_jumpserver/servicechecks/beats/prod"
INV_DIR="$BASE_DIR/inventory"
TEMP_DIR="$BASE_DIR/temp"
HISTORY_FILE="$BASE_DIR/log/beats-prod-servicechecks-run-history"

# --- Inputs/Outputs ---
server_list="$INV_DIR/prod-server-list.txt"
mail_report="$TEMP_DIR/failed-exponow-prod-beats-report.txt"

# --- Style ---
BGREEN='\e[92m'
RED='\e[31m'
NC='\e[0m'

# --- Initialization ---
mkdir -p "$TEMP_DIR" "$(dirname "$HISTORY_FILE")"
> "$mail_report"

# --- Clean up history if file size > 3 Megabytes ---
find "$BASE_DIR" -type f -name "beats-prod-servicechecks-run-history" -size +3M -exec truncate -s 0 {} +

# --- Log execution ---
{ date | tr '\n' ' '; echo "Running Elastic Beats service checks"; } >> "$HISTORY_FILE"

# --- Main Logic ---
echo -e "\n${BGREEN}Checking Elastic Beats status on production servers...${NC}\n"

if [ ! -f "$server_list" ]; then
    echo "ERROR: Server list not found at $server_list"
    exit 1
fi

mb_failed=()
fb_failed=()
hb_failed=()

for server in $(<"$server_list"); do
    echo "----------------------------------------"
    echo "Server: $server"
    echo "----------------------------------------"

    # Single SSH call to query all 3 processes simultaneously to minimize connection overhead
    remote_pids=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 -o LogLevel=error "chq-reinogar@$server" \
        "pgrep -f /prod/app/metricbeat -o || echo 'mb_down'; \
         pgrep -f /prod/app/filebeat -o || echo 'fb_down'; \
         pgrep -f /prod/app/heartbeat -o || echo 'hb_down'")
    
    ssh_status=$?

    if [ $ssh_status -eq 255 ]; then
        echo -e "${RED}SSH ERROR${NC}: Could not connect to $server\n"
        continue
    fi

    # Read the three outputs from the remote execution string
    IFS=$'\n' read -r -d '' mb_status fb_status hb_status <<< "$remote_pids"

    # Evaluate Metricbeat status
    if [ "$mb_status" = "mb_down" ] || [ -z "$mb_status" ]; then
        echo -e "Metricbeat: ${RED}DOWN${NC}"
        mb_failed+=("$server")
    else
        echo -e "Metricbeat: ${BGREEN}OK${NC} (PID: $mb_status)"
    fi

    # Evaluate Filebeat status
    if [ "$fb_status" = "fb_down" ] || [ -z "$fb_status" ]; then
        echo -e "Filebeat:   ${RED}DOWN${NC}"
        fb_failed+=("$server")
    else
        echo -e "Filebeat:   ${BGREEN}OK${NC} (PID: $fb_status)"
    fi

    # Evaluate Heartbeat status
    if [ "$hb_status" = "hb_down" ] || [ -z "$hb_status" ]; then
        echo -e "Heartbeat:  ${RED}DOWN${NC}"
        hb_failed+=("$server")
    else
        echo -e "Heartbeat:  ${BGREEN}OK${NC} (PID: $hb_status)"
    fi
    echo ""
done

# --- Remediation & Reporting ---
total_failures=$(( ${#mb_failed[@]} + ${#fb_failed[@]} + ${#hb_failed[@]} ))

if [ $total_failures -eq 0 ]; then
    echo -e "${BGREEN}All Elastic Beats services are running perfectly across production!${NC}"
    exit 0
fi

# Restart Metricbeat
if [ ${#mb_failed[@]} -gt 0 ]; then
    echo -e "\n${BGREEN}Restarting Metricbeat on failed servers...${NC}\n"
    for target in "${mb_failed[@]}"; do
        new_pid=$(ssh -o StrictHostKeyChecking=no -o LogLevel=error -o ConnectTimeout=3 "chq-reinogar@$target" \
            "sudo -iu metricbeat /prod/app/metricbeat/start.sh > /dev/null 2>&1; pgrep -f /prod/app/metricbeat -o")
        if [ -n "$new_pid" ]; then
            echo "Metricbeat was restarted on $target (PID=$new_pid)" >> "$mail_report"
            echo "Metricbeat restarted on $target"
        fi
    done
fi

# Restart Filebeat
if [ ${#fb_failed[@]} -gt 0 ]; then
    echo -e "\n${BGREEN}Restarting Filebeat on failed servers...${NC}\n"
    for target in "${fb_failed[@]}"; do
        new_pid=$(ssh -o StrictHostKeyChecking=no -o LogLevel=error -o ConnectTimeout=3 "chq-reinogar@$target" \
            "sudo -iu filebeat /prod/app/filebeat/start.sh > /dev/null 2>&1; pgrep -f /prod/app/filebeat -o")
        if [ -n "$new_pid" ]; then
            echo "Filebeat was restarted on $target (PID=$new_pid)" >> "$mail_report"
            echo "Filebeat restarted on $target"
        fi
    done
fi

# Restart Heartbeat
if [ ${#hb_failed[@]} -gt 0 ]; then
    echo -e "\n${BGREEN}Restarting Heartbeat on failed servers...${NC}\n"
    for target in "${hb_failed[@]}"; do
        new_pid=$(ssh -o StrictHostKeyChecking=no -o LogLevel=error -o ConnectTimeout=3 "chq-reinogar@$target" \
            "sudo -iu heartbeat /prod/app/heartbeat/start.sh > /dev/null 2>&1; pgrep -f /prod/app/heartbeat -o")
        if [ -n "$new_pid" ]; then
            echo "Heartbeat was restarted on $target (PID=$new_pid)" >> "$mail_report"
            echo "Heartbeat restarted on $target"
        fi
    done
fi

# Format output file format for windows compatibility if needed
sed -i -e 's/^/\r/' -e '/^[[:space:]]*$/d' "$mail_report"

# --- Email Notification ---
mail -s "ELASTIC-BEATS-SERVICES-DOWN-BUT-RESTARTED" \
     -a "$mail_report" \
     -r "cxpmon@expeditors.com" \
     "tigerteam@abc.com blackpanther@abc.com" <<EOD

Attached is a list of PROD Elastic Beats Services (Metricbeat/Filebeat/Heartbeat) that were DOWN but RESTARTED!

*************************************************************************
EOD

echo -e "\nEmail sent with $(wc -l < "$mail_report") lines of log updates."
#!/usr/bin/env bash

# --- CONFIGURATION ---
THRESHOLD=75
HOSTNAME=$(hostname)
ALERT_FOUND=0

echo "Checking disk space on [$HOSTNAME] (Threshold: ${THRESHOLD}%)..."
echo "--------------------------------------------------------"

# --- DISK CHECK ---
# --output=pcent,target explicitly locks column $1 as % and column $2 as the path.
# grep -v deletes only the text headers, meaning nothing else gets skipped.
while read -r usage path; do
    # Strip the '%' character to get a raw integer
    numeric_usage=${usage//%/}
    
    # Check if the output is a valid number and breaks the threshold
    if [[ "$numeric_usage" =~ ^[0-9]+$ ]] && [ "$numeric_usage" -ge "$THRESHOLD" ]; then
        echo -e "\e[31mCRITICAL:\e[0m Partition '$path' is at ${numeric_usage}% capacity!"
        ALERT_FOUND=1
    fi
done < <(df --output=pcent,target | grep -v "Use%")

# --- STATUS SUMMARY ---
if [ "$ALERT_FOUND" -eq 0 ]; then
    echo -e "\e[32mOK:\e[0m All scanned partitions are below ${THRESHOLD}% capacity."
fi

echo "--------------------------------------------------------"
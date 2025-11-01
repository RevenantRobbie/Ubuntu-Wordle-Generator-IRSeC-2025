#!/bin/bash
#This also generates wordles!
#in case of errors, remove the "sudo" from line 57 and run everything as root
#remember, set up auth keys from root to root
#else adapt
WORDLES="Wordles.txt"
REGIONS="Regions.txt"
PLAYERS="Players.txt"
HIGH_SCORES="HighScores.txt"
DISCORD_INTEGRATION="https://discord.com/api/webhooks/1433989033851093094/3S16Dq1Hu_kqoqiAficJcojhNQKrWD4qvN2gY_wP5Rj0eJ-1p_iIlGcUAH_BDvnfipRD"
echo "Enter path to region storage location"
read -p "> " KEY_PATH
echo "Path set to $KEY_PATH"
echo "Enter account"
read -p "> " ACCOUNT
echo "Path set to $ACCOUNT"
echo "Enter game"
read -p "> " GAME
echo "Recore Scores? (y/n)"
read -p "> " SCORES
PLAYER_LIST=()
WORDLE_LIST=()
CONNECT_TIMEOUT_SECONDS=5
COUNT=0

#secures connections to all hosts
while IFS= read -r REGION_INFO; do
    ssh -o BatchMode=yes -o ConnectTimeout=$CONNECT_TIMEOUT_SECONDS -i "$KEY_PATH" "$ACCOUNT@${REGION_INFO: :-1}" "true" &>/dev/null
    #ssh -o BatchMode=yes -o ConnectTimeout=$CONNECT_TIMEOUT_SECONDS -i "$PREDETERMINED_START_PATH+${REGION_INFO[1]: :-1}" "root@${REGION_INFO[0]}" "true" &>/dev/null
    if [ $? -eq 0 ]; then
        echo "${REGION_INFO} connected successfully."
    else
        echo "!!! UNSUCCESSFUL CONNECTION AT ${REGION_INFO} !!!"
        echo "TERMINATING CONNECTION"
        exit 1
    fi
done < "$REGIONS"


if [ "$SCORES" = "y" ]; then
    echo "$(date)" >> "$HIGH_SCORES"
fi
while IFS= read -r REGION_INFO; do
    echo "$ACCOUNT@${REGION_INFO: :-1}"
    ssh -i "$KEY_PATH" "$ACCOUNT@${REGION_INFO: :-1}" "$GAME"
    if [ "$SCORES" = "y" ]; then
        echo -e "\n" >> "$HIGH_SCORES"
        echo "--- $ACCOUNT@${REGION_INFO: :-1} ---" >> "$HIGH_SCORES"
        echo "$?" >> "$HIGH_SCORES"
        echo -e "\n" >> "$HIGH_SCORES"
    fi
done < "$REGIONS"

if [ "$SCORES" = "y" ]; then
    curl -X POST "$DISCORD_INTEGRATION" \
        -F 'payload_json={"content":"New Things!"}' \
        -F "file1=@${HIGH_SCORES}"
fi

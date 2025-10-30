#!/bin/bash
#This also generates wordles!
#in case of errors, remove the "sudo" from line 57 and run everything as root
#remember, set up auth keys from root to root
#else adapt
WORDLES="Wordles.txt"
REGIONS="Regions.txt"
PLAYERS="Players.txt"
SOLUTIONS="Solutions.txt"
DISCORD_INTEGRATION="https://discord.com/api/webhooks/1433242319058108511/GpOmC2gG1_ZUbN2o0C4K6DVeOCnBHWX-uADI6oYRDZcIRAaNFl-575B-5Ta9D97JojFu"
echo "Enter path to region storage location"
read -p "> " KEY_PATH
echo "Path set to $KEY_PATH"
echo "Enter account"
read -p "> " ACCOUNT
echo "Path set to $ACCOUNT"
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

#generates wordles for each player
while IFS= read -r PLAYER;do
    PLAYER_LIST+=("${PLAYER: :-1}")
    RANDOM_NUM=$((RANDOM % 9000 + 1000))
    WORDLE=$(shuf -n 1 $WORDLES)
    while [[ " ${WORDLE_LIST[*]} " =~ " $WORDLE " ]]; do
        WORDLE=$(shuf -n 1 $WORDLES)
    done
    WORDLE="${WORDLE: :-1}${RANDOM_NUM}"
    WORDLE_LIST+=("$WORDLE")
done < "$PLAYERS"

> "$SOLUTIONS"
echo "$(date)" >> "$SOLUTIONS"
for (( i = 0; i < ${#PLAYER_LIST[@]}; i++ )); do
    echo "${PLAYER_LIST[i]}:${WORDLE_LIST[i]}" | chpasswd #I am assuming you are running this on root right now
    echo -e "${PLAYER_LIST[i]} | ${WORDLE_LIST[i]}\n" >> "$SOLUTIONS"
done

while IFS= read -r REGION_INFO; do
    echo "$ACCOUNT@${REGION_INFO: :-1}"
    for (( i = 0; i < ${#PLAYER_LIST[@]}; i++ )); do
        ssh -i "$KEY_PATH" "$ACCOUNT@${REGION_INFO: :-1}" "echo '${PLAYER_LIST[i]}:${WORDLE_LIST[i]}' | sudo usr/sbin/chpasswd"
        if [ $? -eq 0 ]; then
            echo "Password changed successfully for ${PLAYER_LIST[i]} on region $REGION_INFO"
        else
            echo "Password change failed for ${PLAYER_LIST[i]} on region $REGION_INFO"
            echo "Aborting change process"
            exit 1
fi
    done
done < "$REGIONS"

curl -X POST "$DISCORD_INTEGRATION" \
    -F 'payload_json={"content":"New Passwords!"}' \
    -F "file1=@${SOLUTIONS}"
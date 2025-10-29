#!/bin/bash
#This also generates wordles!
WORDLES="Wordles.txt"
REGIONS="Regions.txt"
PLAYERS="Players.txt"
SOLUTIONS="Solutions.txt"
DISCORD_INTEGRATION="https://discord.com/api/webhooks/1433242319058108511/GpOmC2gG1_ZUbN2o0C4K6DVeOCnBHWX-uADI6oYRDZcIRAaNFl-575B-5Ta9D97JojFu"
echo "Enter path to region storage location"
read -p "> " PREDETERMINED_START_PATH
echo "Path set to $PREDETERMINED_START_PATH"
PLAYER_LIST=()
WORDLE_LIST=()
CONNECT_TIMEOUT_SECONDS=5

#secures connections to all hosts
while IFS= read -r LINE; do
    IFS="|" read -ra REGION_INFO <<< "$LINE"
    ssh -o BatchMode=yes -o ConnectTimeout=$CONNECT_TIMEOUT_SECONDS -i "$PREDETERMINED_START_PATH+${REGION_INFO[1]: :-1}" "root@${REGION_INFO[0]}" "true" &>/dev/null
    if [ $? -eq 0 ]; then
        echo "${REGION_INFO[0]} connected successfully."
    else
        echo "!!! UNSUCCESSFUL CONNECTION AT ${REGION_INFO[0]} !!!"
        echo "TERMINATING CONNECTION"
        exit 1
    fi
done < "$REGIONS"

#generates wordles for each player
while IFS= read -r PLAYER;do
    PLAYER_LIST+=("${PLAYER: :-1}")
    LINE_COUNT=$(wc -l < $WORDLES)
    RANDOM_NUM=$((RANDOM % $LINE_COUNT + 1))
    WORDLE=$(shuf -n 1 $WORDLES)
    while [[ " ${WORDLE_LIST[*]} " =~ " $WORDLE " ]]; do
        WORDLE=$(shuf -n 1 $WORDLES)
    done
    WORDLE_LIST+="$WORDLE"
done < "$PLAYERS"

> "$SOLUTIONS"
echo "$(date)" >> "$SOLUTIONS"
while IFS= read -r LINE; do
    IFS="|" read -ra REGION_INFO <<< "$LINE"
    echo "${REGION_INFO[1]: :-1}" 
    echo "root@${REGION_INFO[0]}"
    for (( i = 0; i < ${#PLAYER_LIST[@]}; i++ )); do
        ssh -i "$PREDETERMINED_START_POINT+${REGION_INFO[1]: :-1}" "root@${REGION_INFO[0]}" "echo '${WORDLE_LIST[i]}' | sudo passwd --stdin '${PLAYER_LIST[i]}"
        if [ "$i" -eq 0 ]; then
            echo "$PLAYER_LIST[i] | $WORDLE_LIST[i]" >> "$SOLUTIONS"
        fi
    done
done < "$REGIONS"

curl -X POST "$DISCORD_INTEGRATION" \
    -F 'payload_json={"content":"testing"}' \
    -F "file1=@${SOLUTIONS}"
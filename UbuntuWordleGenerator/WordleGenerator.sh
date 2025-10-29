#!/bin/bash
#This also generates wordles!
WORDLES="Wordles.txt"
REGIONS="Regions.txt"
PLAYERS="Players.txt"
SOLUTIONS="Solutions.txt"
echo "Enter path to region storage location"
read -p "> " PREDETERMINED_START_PATH
echo "Path set to $PREDETERMINED_START_PATH"
PLAYER_LIST=()
WORDLE_LIST=()
CONNECT_TIMEOUT_SECONDS=5

#secures connections to all hosts
while IFS= read -r line; do
    IFS="|" read -ra REGION_INFO <<< "$line"
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
while IFS= read -r Player;do
    PlayerList+=("${Player: :-1}")
    LineCount=$(wc -l < $Wordles)
    RandomNum=$((RANDOM % $LineCount + 1))
    Wordle=$(shuf -n 1 $Wordles)
    while [[ " ${WordleList[*]} " =~ " $Wordle " ]]; do
        Wordle=$(shuf -n 1 $Wordles)
    done
    WordleList+="$Wordle"
done < "$Players"


# while IFS= read -r line; do
#     IFS="|" read -ra RegionInfo <<< "$line"
#     echo "${RegionInfo[1]: :-1}" 
#     echo "root@${RegionInfo[0]}"
#     for (( i = 0; i < ${#PlayerList[@]}; i++ )); do
#         echo "${PlayerList[i]}"
#         #ssh -i "$PredeterminedStartPoint+${RegionInfo[1]: :-1}" "root@${RegionInfo[0]}" "echo '${WordleList[i]}' | sudo passwd --stdin '${PlayerList[i]}'"
#     done
# done < "$Regions"
# echo "$PlayerList"


#!/bin/bash
# 
# Add game data to the backend
# 
# To clear the existing data please use the following command: 
#   curl -X DELETE {url}

if [ $# = 0 ]; then
    echo "Please supply a url for posting the game data.";
    exit;
fi

# Below is the JSON format in which each game should be posted:
# { 
#     "type": "Game",
#     "fields": { 
#         "Event": "Troll Masters", 
#         "Site": "Gausdal NOR",
#         ...
#     },
#     "moves": "1.d4 Nf6 2.Nf3 d5 3.e3 Bf5 4...."
# }

# Init data with the start of the JSON file.
init_data() {
    data="{"'"type"'": "'"Game"'", "'"fields"'": {";
}

# File with game data.
FILE='chess.pgn';

# All keywords we search for in every game.
keywords=("Event" "Site" "Date" "Round" "WhiteElo" "BlackElo" "White" "Black" "Result" "ECO");

init_data;

# For every line, a check is done to see if the keyword matches a keyword in the keywords array.
# If matched, the keyword will be added to the JSON, with the value.
# This is done for all keywords.
# To make sure, the keyword is not only a part of the keyword that's found in the chess.pgn file,
# we use the * behind it. See line 44.
# After that, the moves are added for the game.
# This is done for every game in the chess.pgn file.

while read value; do
    if [[ ! $value =~ ^1\. ]]; then
        for keyword in "${keywords[@]}"; do
            if [[ "$value" == "[$keyword"* ]]; then
                content=$(grep -o '".*"' <<< "$value");
                data="$data \"$keyword\": $content,";

                break;
            fi
        done

    else
        data=${data%?}; # Remove last comma for proper JSON syntax
        data="$data}, \"moves\": \"$value\"}";

        # Send POST request to the backend with the generated JSON.
        curl -d "$data" -H "Content-Type: application/json" -X POST $1;

        init_data;
    fi
done <"$FILE"

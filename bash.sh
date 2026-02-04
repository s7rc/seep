#!/bin/bash

# A list of normal-looking nicknames to rotate through
NICKS=("Alex_92" "Jordan_M" "Chris_P" "Sam_K88" "Taylor_V" "Morgan_Z" "Casey_J")
NICK=${NICKS[$RANDOM % ${#NICKS[@]}]}

SERVER="irc.orpheus.network"
PORT=7000
CHAN="#recruitment"

echo "Connecting as $NICK..."

{
    echo "NICK $NICK"
    echo "USER $NICK 0 * :$NICK"
    sleep 5
    echo "TOPIC $CHAN"
    sleep 2
    echo "QUIT"
} | openssl s_client -connect $SERVER:$PORT -quiet 2>/dev/null > irc_log.txt

# Logic to check the topic
if grep -qi "OPEN" irc_log.txt; then
    echo "MATCH FOUND: Recruitment is OPEN!"
    exit 1 
elif grep -qi "CLOSED" irc_log.txt; then
    echo "Still closed."
    exit 0
else
    echo "Connection error or blocked by Orpheus."
    exit 0
fi

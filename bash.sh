#!/bin/bash

# Real-looking Nicks
NICKS=("Alex_92" "Jordan_M" "Chris_P" "Sam_K88" "Taylor_V" "Morgan_Z" "Casey_J")
NICK=${NICKS[$RANDOM % ${#NICKS[@]}]}
SERVER="irc.orpheus.network"
PORT=7000
CHAN="#recruitment"

echo "Connecting as $NICK using WeeChat..."

# Run WeeChat with specific commands
# We tell it to connect via SSL, join the channel, wait, then quit.
weechat -d . -r "/server add orp $SERVER/$PORT -ssl; \
/set irc.server.orp.nicks $NICK; \
/connect orp; \
/wait 10s /join $CHAN; \
/wait 5s /print \${buffer.title}; \
/wait 2s /quit" > raw_output.txt 2>&1

# WeeChat logs the buffer title (which is the topic) to the output.
# We check if 'OPEN' is in the resulting log.
if grep -qi "OPEN" raw_output.txt; then
    echo "MATCH FOUND: Recruitment is OPEN!"
    exit 1
elif grep -qi "CLOSED" raw_output.txt; then
    echo "Status: Still CLOSED."
    exit 0
else
    echo "--- LOG START ---"
    cat raw_output.txt
    echo "--- LOG END ---"
    echo "Error: Could not determine topic. Check logs above."
    exit 0
fi

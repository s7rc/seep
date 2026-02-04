#!/bin/bash

NICKS=("Alex_92" "Jordan_M" "Chris_P" "Sam_K88" "Taylor_V" "Morgan_Z" "Casey_J")
NICK=${NICKS[$RANDOM % ${#NICKS[@]}]}
SERVER="irc.orpheus.network"
PORT=7000
CHAN="#recruitment"

echo "Connecting as $NICK..."

# We add 'head -n 100' to capture enough of the start of the session
weechat-headless -d . -r "/server add orp $SERVER/$PORT -ssl; \
/set irc.server.orp.nicks $NICK; \
/connect orp; \
/wait 15s /topic $CHAN; \
/wait 5s /quit" > irc_output.log 2>&1

# Show the log in the GitHub console so we can see what happened
echo "--- IRC LOG OUTPUT ---"
cat irc_output.log
echo "--- END LOG ---"

if grep -qi "OPEN" irc_output.log; then
    echo "RESULT: IT IS OPEN!!"
    exit 1
elif grep -qi "CLOSED" irc_output.log; then
    echo "RESULT: Still Closed."
    exit 0
else
    echo "RESULT: Unknown status (Check the log above)."
    exit 0
fi

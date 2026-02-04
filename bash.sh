#!/bin/bash

NICKS=("Alex_92" "Jordan_M" "Chris_P" "Sam_K88" "Taylor_V" "Morgan_Z" "Casey_J")
NICK=${NICKS[$RANDOM % ${#NICKS[@]}]}
SERVER="irc.orpheus.network"
PORT=7000
CHAN="#recruitment"

echo "Connecting as $NICK..."

# Force WeeChat to log EVERYTHING to a single file immediately
# We use 'timeout' to make sure the process stays open for 30 seconds
timeout 30s weechat-headless -d . -r "/set logger.file.path '.'; \
/set logger.mask.irc 'irc_debug.log'; \
/server add orp $SERVER/$PORT -ssl; \
/set irc.server.orp.nicks $NICK; \
/connect orp; \
/wait 20s /topic $CHAN; \
/wait 5s /quit" > /dev/null 2>&1

# Check if the debug log exists
if [ ! -f "irc_debug.log" ]; then
    echo "ERROR: No log file generated. WeeChat failed to start."
    ls -a
    exit 0
fi

echo "--- FULL IRC TRAFFIC ---"
cat irc_debug.log
echo "--- END TRAFFIC ---"

# Look for the status
if grep -qi "OPEN" irc_debug.log; then
    echo "RESULT: IT IS OPEN!!"
    exit 1
elif grep -qi "CLOSED" irc_debug.log; then
    echo "RESULT: Still Closed."
    exit 0
else
    echo "RESULT: Could not find topic in the logs. Check if blocked."
    exit 0
fi

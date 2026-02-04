#!/bin/bash

NICKS=("Alex_92" "Jordan_M" "Chris_P" "Sam_K88" "Taylor_V" "Morgan_Z" "Casey_J")
NICK=${NICKS[$RANDOM % ${#NICKS[@]}]}
SERVER="irc.orpheus.network"
PORT=7000
CHAN="#recruitment"

echo "Connecting as $NICK..."

# We use -r to run commands. 
# 1. Connect
# 2. Wait 10 seconds (important for the server to stabilize)
# 3. Send raw TOPIC command
# 4. Wait 5 seconds for the reply
# 5. Quit
timeout 40s weechat-headless -d . -r "/set logger.file.path '.'; \
/set logger.mask.irc 'irc_debug.log'; \
/server add orp $SERVER/$PORT -ssl; \
/set irc.server.orp.nicks $NICK; \
/connect orp; \
/wait 10s /raw TOPIC $CHAN; \
/wait 10s /quit" > /dev/null 2>&1

if [ ! -f "irc_debug.log" ]; then
    echo "ERROR: No log file generated."
    exit 0
fi

echo "--- IRC TRAFFIC ---"
# We filter for the topic line (332 is the IRC code for topic)
cat irc_debug.log
echo "--- END TRAFFIC ---"

# Logic: Check if CLOSED is missing OR if OPEN is present
if grep -q "332" irc_debug.log; then
    TOPIC_LINE=$(grep "332" irc_debug.log)
    echo "FOUND TOPIC LINE: $TOPIC_LINE"
    
    if echo "$TOPIC_LINE" | grep -qi "OPEN"; then
        echo "RESULT: IT IS OPEN!!"
        exit 1
    elif echo "$TOPIC_LINE" | grep -qi "CLOSED"; then
        echo "RESULT: Still Closed."
        exit 0
    else
        echo "RESULT: Topic found but status unclear."
        exit 0
    fi
else
    echo "RESULT: Could not find the topic line in logs."
    exit 0
fi

#!/bin/bash

NICKS=("Alex_92" "Jordan_M" "Chris_P" "Sam_K88" "Taylor_V" "Morgan_Z" "Casey_J")
NICK=${NICKS[$RANDOM % ${#NICKS[@]}]}
SERVER="irc.orpheus.network"
PORT=7000
CHAN="#recruitment"

echo "Connecting as $NICK..."

# 1. Connect
# 2. Wait 10s (Let the MOTD finish)
# 3. JOIN the channel (This forces the server to send the topic)
# 4. Wait 10s (To receive the topic text)
# 5. Quit
timeout 45s weechat-headless -d . -r "/set logger.file.path '.'; \
/set logger.mask.irc 'irc_debug.log'; \
/server add orp $SERVER/$PORT -ssl; \
/set irc.server.orp.nicks $NICK; \
/connect orp; \
/wait 10s /join $CHAN; \
/wait 10s /quit" > /dev/null 2>&1

if [ ! -f "irc_debug.log" ]; then
    echo "ERROR: No log file generated."
    exit 0
fi

echo "--- IRC TRAFFIC ---"
# Show us the specific lines about joining and the topic
grep -E "Topic for|332|JOIN|Welcome" irc_debug.log
echo "--- END TRAFFIC ---"

# Check for the topic inside the logs
if grep -qi "Topic for $CHAN" irc_debug.log; then
    TOPIC_LINE=$(grep "Topic for $CHAN" irc_debug.log)
    echo "CAPTURED TOPIC: $TOPIC_LINE"
    
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
    echo "RESULT: Failed to join or get topic. (See traffic above)"
    exit 0
fi

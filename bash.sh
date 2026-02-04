#!/bin/bash

# 1. Config
NICKS=("Alex_92" "Jordan_M" "Chris_P" "Sam_K88" "Taylor_V" "Morgan_Z" "Casey_J")
NICK=${NICKS[$RANDOM % ${#NICKS[@]}]}
SERVER="irc.orpheus.network"
PORT=7000
CHAN="#recruitment"

echo "Connecting as $NICK... (This will take 60 seconds)"

# 2. Run WeeChat with MASSIVE delays
# - Connect
# - Wait 40s (Guarantee connection is done and MOTD is finished)
# - Join
# - Wait 15s (Wait for topic)
# - Quit
timeout 90s weechat-headless -d . -r "/set logger.file.path '.'; \
/set logger.mask.irc 'irc.log'; \
/server add orp $SERVER/$PORT -ssl; \
/set irc.server.orp.nicks $NICK; \
/set irc.server.orp.username $NICK; \
/set irc.server.orp.realname $NICK; \
/connect orp; \
/wait 40s /join $CHAN; \
/wait 15s /quit" > /dev/null 2>&1

# 3. Debug: Did we even get a log?
if [ ! -f "irc.log" ]; then
    echo "ERROR: No log file created."
    exit 0
fi

# 4. Filter the log for the good stuff
echo "--- RELEVANT LOG LINES ---"
grep -E "Welcome|Topic for|332|JOIN|Closing Link" irc.log
echo "--------------------------"

# 5. Check for the topic
TOPIC_LINE=$(grep "Topic for $CHAN" irc.log)

if [ -n "$TOPIC_LINE" ]; then
    echo "SUCCESS! Captured: $TOPIC_LINE"
    
    if echo "$TOPIC_LINE" | grep -qi "OPEN"; then
        echo "✅ STATUS: OPEN! (Triggering Notification)"
        exit 1
    else
        echo "❌ STATUS: CLOSED (or unknown)."
        exit 0
    fi
else
    echo "FAILURE: Connected, but never got the topic. Check the log lines above."
    exit 0
fi

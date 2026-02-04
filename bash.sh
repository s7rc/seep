#!/bin/bash

NICKS=("Alex_92" "Jordan_M" "Chris_P" "Sam_K88" "Taylor_V" "Morgan_Z" "Casey_J")
NICK=${NICKS[$RANDOM % ${#NICKS[@]}]}
SERVER="irc.orpheus.network"
PORT=7000
CHAN="#recruitment"

echo "Connecting as $NICK..."

# We set logging to 'on' and tell weechat exactly where to save it
weechat-headless -d . -r "/set logger.file.path '.'; \
/set logger.level.irc 4; \
/server add orp $SERVER/$PORT -ssl; \
/set irc.server.orp.nicks $NICK; \
/connect orp; \
/wait 15s /topic $CHAN; \
/wait 5s /quit" > /dev/null 2>&1

# WeeChat creates log files based on the server/channel name
# Usually 'irc.orp.#recruitment.weechatlog' or 'irc.server.orp.weechatlog'
LOG_FILE=$(ls *.weechatlog 2>/dev/null | head -n 1)

if [ -z "$LOG_FILE" ]; then
    echo "--- DEBUG INFO ---"
    echo "No log file found. Let's see what files exist:"
    ls -a
    echo "------------------"
    echo "RESULT: Connection failed or timed out."
    exit 0
fi

echo "--- IRC LOG OUTPUT ($LOG_FILE) ---"
cat "$LOG_FILE"
echo "--- END LOG ---"

if grep -qi "OPEN" "$LOG_FILE"; then
    echo "RESULT: IT IS OPEN!!"
    exit 1
elif grep -qi "CLOSED" "$LOG_FILE"; then
    echo "RESULT: Still Closed."
    exit 0
else
    echo "RESULT: Unknown status (Check the log above)."
    exit 0
fi

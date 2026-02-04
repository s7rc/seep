#!/bin/bash

# 1. Install Expect
sudo apt-get -y install expect > /dev/null 2>&1

# 2. Config
SERVER="irc.orpheus.network"
PORT="7000"
CHAN="#recruitment"
NICK="Guest$(date +%s | tail -c 4)"

echo "Connecting as $NICK..."

# 3. Create the Expect script
# We enable 'log_file' to dump everything to disk.
cat <<EOF > irc_bot.exp
log_file -noappend session_dump.log
set timeout 60
spawn openssl s_client -connect $SERVER:$PORT -quiet

# Login Fast
sleep 1
send "NICK $NICK\r"
send "USER $NICK 0 * :$NICK\r"

# Handle the PING/PONG Check + Wait for Welcome
expect {
    -re "PING :(\[^\r\n]+)" {
        send "PONG :\$expect_out(1,string)\r"
        exp_continue
    }
    "Welcome to the Orpheus IRC Network" {
        send "JOIN $CHAN\r"
    }
    timeout {
        exit 1
    }
}

# Once we send JOIN, we just wait 10 seconds to collect all data
# We don't try to parse it here. We just let it fill the log file.
sleep 10
send "QUIT\r"
exit 0
EOF

# 4. Run it
expect irc_bot.exp > /dev/null

# 5. PARSE THE FILE
if [ ! -f "session_dump.log" ]; then
    echo "❌ FATAL: No log file generated."
    exit 0
fi

# We look for code 332 (The Topic Code) specifically
TOPIC_LINE=$(grep " 332 " session_dump.log)

# If 332 isn't found, look for "Topic for"
if [ -z "$TOPIC_LINE" ]; then
    TOPIC_LINE=$(grep "Topic for" session_dump.log)
fi

echo "--- RAW TOPIC LINE ---"
echo "$TOPIC_LINE"
echo "----------------------"

if [ -z "$TOPIC_LINE" ]; then
    echo "⚠️ ERROR: Could not find topic in the logs."
    echo "Here is the last thing the server said:"
    tail -n 5 session_dump.log
    exit 0
fi

# 6. Check Status
if echo "$TOPIC_LINE" | grep -qi "OPEN"; then
    echo "✅ STATUS: OPEN! (Triggering Notification)"
    exit 1
elif echo "$TOPIC_LINE" | grep -qi "CLOSED"; then
    echo "❌ STATUS: CLOSED."
    exit 0
else
    echo "⚠️ STATUS: Unknown. (Topic captured, but keywords missing)"
    exit 0
fi

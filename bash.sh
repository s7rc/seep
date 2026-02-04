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
cat <<EOF > irc_bot.exp
# Log everything to file
log_file -noappend session_dump.log
set timeout 60
spawn openssl s_client -connect $SERVER:$PORT -quiet

# Login
sleep 2
send "NICK $NICK\r"
send "USER $NICK 0 * :$NICK\r"

# 4. Smart Wait Loop
# We handle PINGs, wait for the MOTD to finish, then Join, then wait for Topic.
expect {
    # If server PINGs, we PONG
    -re "PING :(\[^\r\n]+)" {
        send "PONG :\$expect_out(1,string)\r"
        exp_continue
    }
    # Code 376 = End of MOTD. Server is ready.
    "376" {
        send "JOIN $CHAN\r"
        exp_continue
    }
    # Code 332 = The Topic! We got it.
    -re "332.*$CHAN.*:(.*)" {
        # We don't need to do anything else, the log_file has captured it.
        send "QUIT\r"
        exit 0
    }
    # Code 433 = Nickname in use (Just in case)
    "433" {
        send "NICK ${NICK}_\r"
        exp_continue
    }
    timeout {
        # If we waited 60s and never saw code 332
        exit 1
    }
}
EOF

# 5. Run it
expect irc_bot.exp > /dev/null

# 6. Check the log file
TOPIC_LINE=$(grep " 332 " session_dump.log)

echo "--- CHECKING LOGS ---"
if [ -z "$TOPIC_LINE" ]; then
    # Fallback: check for human readable text
    TOPIC_LINE=$(grep "Topic for" session_dump.log)
fi

echo "Captured: $TOPIC_LINE"

if [ -z "$TOPIC_LINE" ]; then
    echo "❌ ERROR: Connected, but Topic never arrived."
    exit 0
fi

# 7. Final Status Check
if echo "$TOPIC_LINE" | grep -qi "OPEN"; then
    echo "✅ STATUS: OPEN! (Triggering Notification)"
    exit 1
elif echo "$TOPIC_LINE" | grep -qi "CLOSED"; then
    echo "❌ STATUS: CLOSED."
    exit 0
else
    echo "⚠️ STATUS: Unknown (Topic found, but keywords missing)."
    exit 0
fi

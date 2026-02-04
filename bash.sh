#!/bin/bash

# 1. Install 'expect' if missing
sudo apt-get -y install expect > /dev/null 2>&1

# 2. Config
SERVER="irc.orpheus.network"
PORT="7000"
CHAN="#recruitment"
# Use a random number to avoid "Nick already in use" errors
NICK="Guest$(date +%s | tail -c 4)"

echo "Connecting as $NICK..."

# 3. Create the Expect script
cat <<EOF > irc_bot.exp
set timeout 60
spawn openssl s_client -connect $SERVER:$PORT -quiet

# DO NOT WAIT. Send login immediately to beat the timeout.
sleep 1
send "NICK $NICK\r"
send "USER $NICK 0 * :$NICK\r"

# NOW we wait for the server to let us in
expect {
    "Welcome to the Orpheus IRC Network" {
        send "JOIN $CHAN\r"
    }
    timeout {
        puts "Error: Timed out waiting for Welcome message."
        exit 1
    }
}

# Wait for the topic (Code 332)
expect {
    -re "332.*$CHAN.*:(.*)" {
        set topic \$expect_out(1,string)
        # Write topic to file
        set fh [open "topic_result.txt" w]
        puts \$fh "\$topic"
        close \$fh
        send "QUIT\r"
        exit 0
    }
    "Interviews are CLOSED" {
         # Sometimes it appears in the text without the 332 code
         set fh [open "topic_result.txt" w]
         puts \$fh "CLOSED"
         close \$fh
         send "QUIT\r"
         exit 0
    }
    timeout {
        puts "Error: Timed out waiting for TOPIC."
        exit 1
    }
}
EOF

# 4. Run it
expect irc_bot.exp > debug_log.txt

# 5. Check the result
if [ -f "topic_result.txt" ]; then
    TOPIC=$(cat topic_result.txt)
    echo "CAPTURED TOPIC: $TOPIC"
    
    if echo "$TOPIC" | grep -qi "OPEN"; then
        echo "✅ STATUS: OPEN! (Triggering Notification)"
        exit 1
    else
        echo "❌ STATUS: CLOSED."
        exit 0
    fi
else
    echo "⚠️ FAILED. Here is the debug log:"
    cat debug_log.txt
    exit 0
fi

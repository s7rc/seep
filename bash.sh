#!/bin/bash

# 1. Install Expect
sudo apt-get -y install expect > /dev/null 2>&1

# 2. Config
SERVER="irc.orpheus.network"
PORT="7000"
CHAN="#recruitment"
NICK="Guest$(date +%s | tail -c 4)"

echo "Connecting as $NICK..."

# 3. Generate the Script
cat <<EOF > irc_bot.exp
set timeout 60
spawn openssl s_client -connect $SERVER:$PORT -quiet

# Send Identity immediately
sleep 1
send "NICK $NICK\r"
send "USER $NICK 0 * :$NICK\r"

# 4. THE CRITICAL PART: Handle the PING/PONG loop
# We wait for EITHER a "PING" or "Welcome".
expect {
    # If server sends PING :12345, we MUST send PONG :12345
    -re "PING :(\[^\r\n]+)" {
        send "PONG :\$expect_out(1,string)\r"
        # 'exp_continue' means "Okay, I handled the PING, now go back to waiting for Welcome"
        exp_continue
    }
    "Welcome to the Orpheus IRC Network" {
        # Success! We are in.
        send "JOIN $CHAN\r"
    }
    timeout {
        puts "Error: Timed out waiting for PING or Welcome."
        exit 1
    }
}

# 5. Get the Topic
expect {
    -re "332.*$CHAN.*:(.*)" {
        set topic \$expect_out(1,string)
        set fh [open "topic_result.txt" w]
        puts \$fh "\$topic"
        close \$fh
        send "QUIT\r"
        exit 0
    }
    timeout {
        puts "Error: Timed out waiting for TOPIC."
        exit 1
    }
}
expect eof
EOF

# 6. Run it
expect irc_bot.exp > debug_log.txt

# 7. Check Result
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
    echo "⚠️ FAILED. Debug Log:"
    cat debug_log.txt
    exit 0
fi

#!/bin/bash

# 1. Install 'expect' (Standard tool for automating interactive shells)
sudo apt-get -y install expect > /dev/null 2>&1

# 2. Configure
SERVER="irc.orpheus.network"
PORT="7000"
CHAN="#recruitment"
NICK="Guest$(date +%s | tail -c 3)"

echo "Connecting as $NICK using Expect..."

# 3. Create the automation script on the fly
cat <<EOF > irc_bot.exp
set timeout 60
# Connect securely
spawn openssl s_client -connect $SERVER:$PORT -quiet
# Wait for SSL handshake to finish
expect "Verify return code"
sleep 2

# Send Login
send "NICK $NICK\r"
send "USER $NICK 0 * :$NICK\r"

# WAIT for the server to explicitly welcome us (No more guessing seconds!)
expect "Welcome to the Orpheus IRC Network"

# Now that we are confirmed inside, JOIN immediately
send "JOIN $CHAN\r"

# Wait for the Topic code (332)
expect {
    -re "332.*$CHAN.*:(.*)" {
        # We captured the topic! Save it to a file.
        set topic \$expect_out(1,string)
        set fh [open "topic_result.txt" w]
        puts \$fh "\$topic"
        close \$fh
        send "QUIT\r"
        exit 0
    }
    timeout {
        exit 1
    }
}
expect eof
EOF

# 4. Run it
expect irc_bot.exp > debug_log.txt

# 5. Check the result
if [ -f "topic_result.txt" ]; then
    TOPIC=$(cat topic_result.txt)
    echo "✅ SUCCESS! Topic Found: $TOPIC"
    
    if echo "$TOPIC" | grep -qi "OPEN"; then
        echo "STATUS: OPEN! (Triggering Alert)"
        exit 1
    else
        echo "STATUS: CLOSED."
        exit 0
    fi
else
    echo "❌ FAILURE. Could not capture topic."
    echo "--- DEBUG LOG ---"
    cat debug_log.txt
    exit 0
fi

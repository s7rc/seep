#!/bin/bash

# 1. Install Expect (Standard Linux tool, lighter than WeeChat)
sudo apt-get -y install expect > /dev/null 2>&1

# 2. Config
SERVER="irc.orpheus.network"
PORT="7000"
CHAN="#recruitment"
NICK="Guest$(date +%s | tail -c 4)"

# Your Discord Webhook URL
WEBHOOK_URL="https://discord.com/api/webhooks/1468585146440618132/di6o9HhZnbCHfif-JQXvdjXsboYO9xm6B1K04RD_aSMgJdbJ41gJNJkSlMHUp31WCfiE"

echo "Connecting as $NICK..."

# 3. Create the Expect script (Handles the login & PING/PONG)
cat <<EOF > irc_bot.exp
log_file -noappend session_dump.log
set timeout 60
spawn openssl s_client -connect $SERVER:$PORT -quiet

# Login
sleep 2
send "NICK $NICK\r"
send "USER $NICK 0 * :$NICK\r"

# Smart Wait Loop
expect {
    # If server PINGs, we PONG to stay alive
    -re "PING :(\[^\r\n]+)" {
        send "PONG :\$expect_out(1,string)\r"
        exp_continue
    }
    # Code 376 = End of MOTD (Welcome message done)
    "376" {
        send "JOIN $CHAN\r"
        exp_continue
    }
    # Code 332 = The Topic! We got it.
    -re "332.*$CHAN.*:(.*)" {
        send "QUIT\r"
        exit 0
    }
    # Code 433 = Nickname in use (Retry with underscore)
    "433" {
        send "NICK ${NICK}_\r"
        exp_continue
    }
    timeout {
        exit 1
    }
}
EOF

# 4. Run the bot
expect irc_bot.exp > /dev/null

# 5. Clean & Check Logs
TOPIC_LINE=$(grep " 332 " session_dump.log)
if [ -z "$TOPIC_LINE" ]; then
    TOPIC_LINE=$(grep "Topic for" session_dump.log)
fi

# Clean up the text (Remove the timestamp/IP junk)
CLEAN_TOPIC=$(echo "$TOPIC_LINE" | sed 's/.*332.*://' | sed 's/.*Topic for.*://')

echo "--- CAPTURED TOPIC ---"
echo "$CLEAN_TOPIC"
echo "----------------------"

if [ -z "$CLEAN_TOPIC" ]; then
    echo "⚠️ ERROR: Connected, but Topic never arrived."
    exit 0
fi

# 6. LOGIC: ONLY trigger if it explicitly says "Interviews are OPEN"
if echo "$CLEAN_TOPIC" | grep -qi "Interviews are OPEN"; then
    echo "✅ STATUS: OPEN! Sending Discord Ping..."
    
    # Send Notification with @everyone to ping you
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"@everyone 🚨 **ORPHEUS INTERVIEWS ARE OPEN!** 🚨\n\n**Topic:** $CLEAN_TOPIC\n\nGO GO GO!\"}" \
         "$WEBHOOK_URL"
         
    exit 1 # Exit 1 triggers the GitHub "Failure" mark so you see it in the list
    
elif echo "$CLEAN_TOPIC" | grep -qi "Interviews are CLOSED"; then
    echo "❌ STATUS: CLOSED. (Correctly detected)"
    exit 0
else
    echo "⚠️ STATUS: Unknown (Keywords missing, not risking a false alarm)."
    exit 0
fi

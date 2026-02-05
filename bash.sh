#!/bin/bash

# 1. Install Expect
sudo apt-get -y install expect > /dev/null 2>&1

# 2. Config
SERVER="irc.orpheus.network"
PORT="7000"
CHAN="#recruitment"
NICK="Guest$(date +%s | tail -c 4)"

# Discord Webhook URLs
WEBHOOK_URL="https://discord.com/api/webhooks/1468585146440618132/di6o9HhZnbCHfif-JQXvdjXsboYO9xm6B1K04RD_aSMgJdbJ41gJNJkSlMHUp31WCfiE"
LOGS_WEBHOOK_URL="https://discord.com/api/webhooks/1468924589051478138/e1R_s1KGA2wkTHADwgkhHlUl86n44vnqKJEWKLG_Z2JZjmUWLDbKKoO3cRXstgVDPcid"

echo "Connecting as $NICK..."

# 3. Create the Expect script
cat <<EOF > irc_bot.exp
log_file -noappend session_dump.log
set timeout 60
spawn openssl s_client -connect $SERVER:$PORT -quiet

sleep 2
send "NICK $NICK\r"
send "USER $NICK 0 * :$NICK\r"

expect {
    -re "PING :(\[^\r\n]+)" {
        send "PONG :\$expect_out(1,string)\r"
        exp_continue
    }
    "376" {
        send "JOIN $CHAN\r"
        exp_continue
    }
    -re "332.*$CHAN.*:(.*)" {
        send "QUIT\r"
        exit 0
    }
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

# Clean up the text
CLEAN_TOPIC=$(echo "$TOPIC_LINE" | sed 's/.*332.*://' | sed 's/.*Topic for.*://' | tr -d '\r')

echo "--- CAPTURED TOPIC ---"
echo "$CLEAN_TOPIC"
echo "----------------------"

if [ -z "$CLEAN_TOPIC" ]; then
    echo "⚠️ ERROR: Connected, but Topic never arrived."
    exit 0
fi

# 6. LOGIC
if echo "$CLEAN_TOPIC" | grep -qi "Interviews are OPEN"; then
    echo "✅ STATUS: OPEN! Sending Discord Ping..."
    
    # Send Notification to Main Channel with @everyone
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"@everyone 🚨 **ORPHEUS INTERVIEWS ARE OPEN!** 🚨\n\n**Topic:** $CLEAN_TOPIC\"}" \
         "$WEBHOOK_URL"
    
    # Also log it to the all-logs channel
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"✅ **LOG:** Status is OPEN\n$CLEAN_TOPIC\"}" \
         "$LOGS_WEBHOOK_URL"
         
    exit 1 
    
elif echo "$CLEAN_TOPIC" | grep -qi "Interviews are CLOSED"; then
    echo "❌ STATUS: CLOSED. Sending log..."
    
    # Send to the logs channel only
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"⚪ **Status Check:** Interviews are **CLOSED**.\n**Topic:** $CLEAN_TOPIC\"}" \
         "$LOGS_WEBHOOK_URL"

    exit 0
else
    echo "⚠️ STATUS: Unknown. Sending log..."
    
    # Log unknown status so you can see if the formatting changed
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\": \"⚠️ **Status Unknown:** Could not find OPEN/CLOSED keywords.\n**Raw Topic:** $CLEAN_TOPIC\"}" \
         "$LOGS_WEBHOOK_URL"
         
    exit 0
fi

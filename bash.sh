#!/bin/bash

# Configuration
SERVER="irc.orpheus.network"
PORT=7000
# Generates a random nickname so the server doesn't think you're a ghost
NICK="WaitBot$(date +%s | tail -c 4)"
CHAN="#recruitment"

echo "Connecting to $SERVER..."

# Send commands to the server
{
    echo "NICK $NICK"
    echo "USER $NICK 8 * :StatusBot"
    sleep 4 # Wait for the server to finish its 'Welcome' messages
    echo "TOPIC $CHAN"
    sleep 2 # Wait for the topic to arrive
    echo "QUIT"
} | openssl s_client -connect $SERVER:$PORT -quiet 2>/dev/null > irc_log.txt

# Search for the status in the log
if grep -qi "OPEN" irc_log.txt; then
    echo "!!! RECRUITMENT IS OPEN !!!"
    exit 1 # Trigger GitHub "Fail" notification (your alert)
elif grep -qi "CLOSED" irc_log.txt; then
    echo "Status: Still CLOSED."
    exit 0
else
    echo "Error: Could not find topic. Server might be blocking the connection."
    exit 0
fi

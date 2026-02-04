#!/bin/bash

# Define a pool of realistic nicknames
NICKS=("Alex_92" "Jordan_M" "Chris_P" "Sam_K88" "Taylor_V" "Morgan_Z" "Casey_J")
NICK=${NICKS[$RANDOM % ${#NICKS[@]}]}
SERVER="irc.orpheus.network"
PORT=7000
CHAN="#recruitment"

echo "Setting up irssi to connect as $NICK..."

# 1. Create a tiny irssi script to automate the check
# This tells irssi: Connect -> Join -> Log Topic -> Quit
mkdir -p ~/.irssi
cat <<EOF > ~/.irssi/check_topic.pl
use strict;
use Irssi;

sub on_topic {
    my (\$server, \$chan, \$topic, \$who, \$setby) = @_;
    if (\$chan eq "$CHAN") {
        # Write topic to a file we can read later
        open(my \$fh, '>', 'irc_topic.txt');
        print \$fh \$topic;
        close(\$fh);
        # We got what we came for, leave.
        \$server->command("QUIT Found topic");
    }
}

Irssi::signal_add('message topic', 'on_topic');
EOF

# 2. Run irssi in the background
# -n sets nick, -c connects, --config uses a clean setup
irssi -n "$NICK" -c $SERVER -p $PORT --use-tls --config=/dev/null <<-EOF &
/script load ~/.irssi/check_topic.pl
/join $CHAN
/wait 15
/quit
EOF

# Wait a few seconds for irssi to do its thing
sleep 20

# 3. Check the result
if [ -f irc_topic.txt ]; then
    TOPIC=$(cat irc_topic.txt)
    echo "TOPIC FOUND: \$TOPIC"
    
    if echo "\$TOPIC" | grep -qi "OPEN"; then
        echo "!!! RECRUITMENT IS OPEN !!!"
        exit 1 # Fails the action to trigger your email/alert
    else
        echo "Status: Still CLOSED."
        exit 0
    fi
else
    echo "Error: Irssi could not capture the topic. The server might be blocking GitHub IPs."
    exit 0
fi

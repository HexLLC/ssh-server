#!/bin/bash

# Start SSH service in the background
/usr/sbin/sshd -D &

# Run ngrok HTTP tunnel on port 80 using the provided authtoken
ngrok http 80 --authtoken ${NGROK_AUTHTOKEN}

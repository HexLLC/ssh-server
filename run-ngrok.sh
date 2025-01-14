#!/bin/bash

# Start SSH service
/usr/sbin/sshd -D &

# Run ngrok with the provided authtoken and tunnel HTTP traffic on port 80
ngrok http 80 --authtoken ${NGROK_AUTHTOKEN}

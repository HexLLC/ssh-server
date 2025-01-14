FROM debian:bullseye-slim

# Build arguments
ARG NGROK_TOKEN
ARG PORT=22

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    NGROK_TOKEN=${NGROK_TOKEN} \
    PORT=${PORT}

# Install required packages
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        openssh-server \
        python3 \
        curl \
        sudo \
        netcat \
        && \
    curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list && \
    apt-get update && \
    apt-get install -y ngrok && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create python script to parse ngrok output
RUN echo '#!/usr/bin/python3\nimport sys, json\ntunnels = json.load(sys.stdin).get("tunnels", [])\nif tunnels:\n    public_url = tunnels[0]["public_url"][6:]\n    host, port = public_url.split(":")\n    print(f"SSH info:\\nssh root@{host} -p {port}\\nROOT Password: craxid")\nelse:\n    print("Ngrok tunnels not found.")' > /parse_tunnel.py \
    && chmod +x /parse_tunnel.py

# Configure SSH and create startup script
RUN mkdir -p /run/sshd && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'root:craxid' | chpasswd && \
    echo '#!/bin/bash' > /start.sh && \
    echo 'service ssh start' >> /start.sh && \
    echo 'ngrok config add-authtoken ${NGROK_TOKEN}' >> /start.sh && \
    echo 'ngrok tcp ${PORT} > /ngrok.log 2>&1 &' >> /start.sh && \
    echo 'sleep 5' >> /start.sh && \
    echo 'while true; do' >> /start.sh && \
    echo '    if curl -s localhost:4040/api/tunnels | /parse_tunnel.py; then' >> /start.sh && \
    echo '        echo "Tunnel established successfully"' >> /start.sh && \
    echo '        break' >> /start.sh && \
    echo '    fi' >> /start.sh && \
    echo '    echo "Waiting for tunnel..."' >> /start.sh && \
    echo '    sleep 2' >> /start.sh && \
    echo 'done' >> /start.sh && \
    echo 'tail -f /ngrok.log' >> /start.sh && \
    chmod +x /start.sh

# Expose necessary port
EXPOSE 22 4040 80

# Start services
CMD ["/start.sh"]

FROM debian:latest

# Define build-time arguments
ARG NGROK_TOKEN
ARG PORT=3389

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV NGROK_TOKEN=${NGROK_TOKEN}
ENV PORT=${PORT}

# Install necessary dependencies and Ngrok
RUN apt update && apt upgrade -y && apt install -y \
    curl gnupg2 lsb-release sudo \
    xrdp xfce4 xfce4-goodies \
    && curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
    && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list \
    && apt update \
    && apt install -y ngrok

# Configure xRDP
RUN echo "root:craxid" | chpasswd \
    && echo "xfce4-session" > /etc/skel/.xsession \
    && sed -i 's/^#port=3389/port=3389/' /etc/xrdp/xrdp.ini \
    && sed -i 's/^#MaxSessions=10/MaxSessions=50/' /etc/xrdp/xrdp.ini

# Add Ngrok authtoken
RUN ngrok config add-authtoken ${NGROK_TOKEN}

# Create Python script to parse and display Ngrok output
RUN echo '#!/usr/bin/python3\nimport sys, json\ntry:\n    tunnels = json.load(sys.stdin).get("tunnels", [])\n    if tunnels:\n        public_url = tunnels[0]["public_url"][6:]  # Strip "tcp://"\n        host, port = public_url.split(":")\n        print(f"\\n--- RDP Credentials ---\\nHost: {host}\\nPort: {port}\\nUsername: root\\nPassword: craxid\\n")\n    else:\n        print("Ngrok tunnels not found.")\nexcept Exception as e:\n    print(f"Error parsing Ngrok output: {e}")' > /parse_tunnel.py \
    && chmod +x /parse_tunnel.py

# Create startup script
RUN echo "#!/bin/bash" > /start.sh \
    && echo "service xrdp start" >> /start.sh \
    && echo "ngrok tcp ${PORT} > /dev/null 2>&1 &" >> /start.sh \
    && echo "sleep 5" >> /start.sh \
    && echo "curl -s http://localhost:4040/api/tunnels | /parse_tunnel.py" >> /start.sh \
    && chmod +x /start.sh

# Expose RDP port
EXPOSE 3389

# Start the services
CMD ["/start.sh"]

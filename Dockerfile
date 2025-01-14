FROM debian:latest

# Define build-time arguments
ARG NGROK_TOKEN
ARG PORT=3389

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV NGROK_TOKEN=${NGROK_TOKEN}
ENV PORT=${PORT}

# Install necessary dependencies and ngrok
RUN apt update && apt upgrade -y && apt install -y \
    curl gnupg2 lsb-release sudo \
    xrdp xfce4 xfce4-terminal dbus-x11 x11-apps \
    && curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
    && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list \
    && apt update \
    && apt install -y ngrok \
    && apt clean

# Add Ngrok authtoken
RUN ngrok config add-authtoken ${NGROK_TOKEN}

# Configure xRDP
RUN echo xfce4-session >~/.xsession \
    && sed -i 's/^port=3389/port=-1/' /etc/xrdp/xrdp.ini \
    && sed -i 's/^FUSEMountName=.*/FUSEMountName=xfuse/' /etc/xrdp/sesman.ini \
    && useradd -m -s /bin/bash user \
    && echo "user:craxid" | chpasswd \
    && adduser user sudo

# Create python script to parse ngrok output
RUN echo '#!/usr/bin/python3\nimport sys, json\ntunnels = json.load(sys.stdin).get("tunnels", [])\nif tunnels:\n    public_url = tunnels[0]["public_url"][6:]\n    host, port = public_url.split(":")\n    print(f"RDP info:\\nConnect to {host}:{port}\\nUsername: user\\nPassword: craxid")\nelse:\n    print("Ngrok tunnels not found.")' > /parse_tunnel.py \
    && chmod +x /parse_tunnel.py

# Add the startup script
RUN echo "#!/bin/bash" > /start_rdp.sh \
    && echo "/usr/local/bin/ngrok tcp ${PORT} > /dev/null 2>&1 &" >> /start_rdp.sh \
    && echo "sleep 5" >> /start_rdp.sh \
    && echo "curl -s http://localhost:4040/api/tunnels | /parse_tunnel.py" >> /start_rdp.sh \
    && echo "echo 'Container is running... Use Ctrl+C to stop'" >> /start_rdp.sh \
    && echo "/etc/init.d/xrdp start" >> /start_rdp.sh \
    && echo 'while true; do sleep 3600; done' >> /start_rdp.sh \
    && chmod +x /start_rdp.sh

# Expose necessary ports
EXPOSE 80 443 3389 4040 8080 8888

# Start the container with the RDP script
CMD ["/start_rdp.sh"]

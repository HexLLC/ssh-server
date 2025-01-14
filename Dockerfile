# Use the latest Debian image as the base
FROM debian:latest

# Define build-time arguments
ARG NGROK_TOKEN
ARG REGION=ap
ARG PORT=22

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV NGROK_TOKEN=${NGROK_TOKEN}
ENV REGION=${REGION}
ENV PORT=${PORT}

# Install necessary dependencies and ngrok
RUN apt update && apt upgrade -y && apt install -y \
    curl gnupg2 lsb-release sudo \
    openssh-server \
    python3 \
    && curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
    && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list \
    && apt update \
    && apt install -y ngrok

# Add Ngrok authtoken
RUN ngrok config add-authtoken ${NGROK_TOKEN}

# Create necessary directories and add the startup script
RUN mkdir /run/sshd \
    && echo "/usr/local/bin/ngrok tcp --authtoken ${NGROK_TOKEN} --region ${REGION} ${PORT} &" >> /openssh.sh \
    && echo "sleep 5" >> /openssh.sh \
    && echo "curl -s http://localhost:4040/api/tunnels | python3 -c \"import sys, json; tunnels = json.load(sys.stdin).get('tunnels', []); public_url = tunnels[0]['public_url'][6:] if tunnels else ''; print('SSH info:\\nssh root@' + public_url.replace(':', ' -p ') + '\\nROOT Password: craxid') if public_url else print('Ngrok tunnels not found.')\"" >> /openssh.sh \
    && echo '/usr/sbin/sshd -D' >> /openssh.sh \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo root:craxid | chpasswd \
    && chmod 755 /openssh.sh

# Expose necessary ports
EXPOSE 80 443 3306 4040 5432 5700 5701 5010 6800 6900 8080 8888 9000

# Start the container with the openssh script
CMD /openssh.sh

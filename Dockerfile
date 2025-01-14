FROM debian

# Define arguments for Ngrok token and region
ARG NGROK_TOKEN
ARG REGION=ap

# Set environment variable to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update package lists, upgrade, and install required packages
RUN apt update && apt upgrade -y && apt install -y \
    ssh wget unzip vim curl python3

# Download and install Ngrok
RUN wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz -O /ngrok-v3-stable-linux-amd64.tgz \
    && cd / \
    && unzip ngrok-v3-stable-linux-amd64.tgz \
    && mv ngrok-v3-stable-linux-amd64/ngrok /ngrok \
    && chmod +x /ngrok

# Setup SSH and Ngrok
RUN mkdir /run/sshd \
    && echo "/ngrok tcp --authtoken ${NGROK_TOKEN} --region ${REGION} 22 &" >> /openssh.sh \
    && echo "sleep 5" >> /openssh.sh \
    && echo "curl -s http://localhost:4040/api/tunnels | python3 -c \"import sys, json; print(\\\"ssh info:\\n\\\",\\\"ssh\\\",\\\"root@\\\"+json.load(sys.stdin)['tunnels'][0]['public_url'][6:].replace(':', ' -p '),\\\"\\nROOT Password:craxid\\\")\" || echo \"\\nError: NGROK_TOKEN missing or invalid. Please provide a valid token.\" \"" >> /openssh.sh \
    && echo '/usr/sbin/sshd -D' >> /openssh.sh \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo root:craxid | chpasswd \
    && chmod 755 /openssh.sh

# Expose necessary ports for Ngrok, SSH, and other services
EXPOSE 80 443 3306 4040 5432 5700 5701 5010 6800 6900 8080 8888 9000

# Start the SSH and Ngrok setup script
CMD /openssh.sh

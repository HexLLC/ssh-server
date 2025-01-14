FROM debian:latest

# Define build-time arguments
ARG NGROK_TOKEN
ARG PORT=22

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV NGROK_TOKEN=${NGROK_TOKEN}
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

# Create python script to parse ngrok output
RUN echo '#!/usr/bin/python3\nimport sys, json\ntunnels = json.load(sys.stdin).get("tunnels", [])\nif tunnels:\n    public_url = tunnels[0]["public_url"][6:]\n    host, port = public_url.split(":")\n    print(f"SSH info:\\nssh root@{host} -p {port}\\nROOT Password: craxid")\nelse:\n    print("Ngrok tunnels not found.")' > /parse_tunnel.py \
    && chmod +x /parse_tunnel.py

# Create necessary directories and add the startup script
RUN mkdir /run/sshd \
    && echo "/usr/local/bin/ngrok tcp ${PORT} &" >> /openssh.sh \
    && echo "sleep 5" >> /openssh.sh \
    && echo "curl -s http://localhost:4040/api/tunnels | /parse_tunnel.py" >> /openssh.sh \
    && echo '/usr/sbin/sshd -D' >> /openssh.sh \
    && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config \
    && echo root:craxid | chpasswd \
    && chmod 755 /openssh.sh

# Expose necessary ports
EXPOSE 80 443 3306 4040 5432 5700 5701 5010 6800 6900 8080 8888 9000

# Start the container with the openssh script
CMD /openssh.sh

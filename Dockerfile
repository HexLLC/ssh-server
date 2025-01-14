FROM debian:bullseye-slim

# Build arguments
ARG NGROK_TOKEN
ARG PORT=22
ARG S6_OVERLAY_VERSION=3.1.5.0

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    NGROK_TOKEN=${NGROK_TOKEN} \
    PORT=${PORT} \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES=1

# Install base packages and security tools
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        openssh-server \
        python3 \
        python3-pip \
        curl \
        wget \
        gnupg2 \
        sudo \
        fail2ban \
        ufw \
        google-authenticator \
        node-exporter \
        netcat \
        tzdata \
        ca-certificates \
        xz-utils && \
    # Install ngrok
    curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list && \
    apt-get update && \
    apt-get install -y ngrok && \
    # Install S6 overlay
    wget -q https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /s6-overlay-noarch.tar.xz && \
    wget -q https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz && \
    tar -C / -Jxpf /s6-overlay-x86_64.tar.xz && \
    # Cleanup
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* *.tar.xz

# Copy configuration files and scripts
COPY rootfs /
RUN chmod +x /usr/local/bin/* /etc/s6-overlay/scripts/*

# Configure SSH and security
RUN mkdir -p /run/sshd && \
    # Configure SSH
    echo 'PermitRootLogin no' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'AllowUsers ${ADMIN_USER}' >> /etc/ssh/sshd_config && \
    echo 'MaxAuthTries ${MAX_AUTH_TRIES}' >> /etc/ssh/sshd_config && \
    # Configure UFW
    ufw default deny incoming && \
    ufw default allow outgoing && \
    ufw allow ssh && \
    ufw allow 9100/tcp && \
    # Configure fail2ban
    echo '[sshd]' >> /etc/fail2ban/jail.local && \
    echo 'enabled = true' >> /etc/fail2ban/jail.local && \
    echo 'bantime = 1h' >> /etc/fail2ban/jail.local && \
    echo 'findtime = 1h' >> /etc/fail2ban/jail.local && \
    echo 'maxretry = 3' >> /etc/fail2ban/jail.local

# Set working directory
WORKDIR /root

# Expose ports
EXPOSE 22 9100

# Use S6 overlay as entrypoint
ENTRYPOINT ["/init"]

FROM debian:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt update && apt upgrade -y && apt install -y \
    sudo xfce4 xfce4-terminal dbus-x11 x11-apps \
    novnc websockify x11vnc supervisor curl

# Set up a user for remote desktop access
RUN useradd -m -s /bin/bash user \
    && echo "user:craxid" | chpasswd \
    && adduser user sudo

# Configure x11vnc and NoVNC
RUN mkdir -p /etc/novnc /var/log/supervisor \
    && echo '#!/bin/bash\nx11vnc -display :0 -nopw -forever -rfbport 5900 &\nwebsockify --web /usr/share/novnc/ 6080 localhost:5900' > /start_vnc.sh \
    && chmod +x /start_vnc.sh

# Supervisor config for managing services
RUN echo '[supervisord]\nnodaemon=true\n\n[program:x11vnc]\ncommand=/start_vnc.sh\n\n[program:xfce4]\ncommand=startxfce4' > /etc/supervisor/supervisord.conf

# Expose ports
EXPOSE 80 443 6080

# Start Supervisor to manage services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

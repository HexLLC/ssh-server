FROM ngrok/ngrok

# Install necessary packages for SSH and other utilities
RUN apt update && apt upgrade -y && apt install -y \
    ssh wget vim curl python3

# Expose necessary ports (e.g., HTTP, SSH, etc.)
EXPOSE 80 443 3306 4040 5432 5700 5701 5010 6800 6900 8080 8888 9000

# Copy the ngrok setup script into the container
COPY run-ngrok.sh /run-ngrok.sh
RUN chmod +x /run-ngrok.sh

# Command to run ngrok and SSH service
CMD ["/run-ngrok.sh"]

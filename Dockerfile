FROM debian

# Set the environment variable for non-interactive package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages for SSH
RUN apt update && apt upgrade -y && apt install -y \
    ssh wget unzip vim curl python3

# Install ngrok by pulling the official Docker image
RUN apt install -y docker.io

# Copy the ngrok command to run it with your authtoken
COPY run-ngrok.sh /run-ngrok.sh
RUN chmod +x /run-ngrok.sh

# Expose the necessary ports (80 for HTTP, 443 for HTTPS, etc.)
EXPOSE 80 443 3306 4040 5432 5700 5701 5010 6800 6900 8080 8888 9000

# Set the command to run ngrok when the container starts
CMD ["/run-ngrok.sh"]

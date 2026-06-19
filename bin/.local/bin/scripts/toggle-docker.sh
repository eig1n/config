#!/bin/bash

# Define all Docker and container components
SERVICES=("docker.service" "docker.socket" "containerd.service")

# Check if the main docker service is active
if systemctl is-active --quiet docker.service; then
    echo "🔄 Docker is currently RUNNING. Shutting everything down..."
    
    # Stop and disable all components
    sudo systemctl stop "${SERVICES[@]}"
    sudo systemctl disable "${SERVICES[@]}"
    
    echo "🛑 All Docker services and sockets are now STOPPED and DISABLED."
else
    echo "🔄 Docker is currently STOPPED. Activating everything..."
    
    # Enable and start all components
    sudo systemctl enable "${SERVICES[@]}"
    sudo systemctl start "${SERVICES[@]}"
    
    echo "🚀 All Docker services and sockets are now ENABLED and RUNNING."
fi

# Show final status summary
echo -e "\n📊 Current Status:"
systemctl is-active "${SERVICES[@]}"


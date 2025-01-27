#!/bin/bash

# Script to automatically set up systemd services for Podman containers with restart=always policy

echo "🔍 Checking for containers with restart=always policy..."

# Enable lingering for current user if not already enabled
if ! loginctl show-user $USER | grep -q "Linger=yes"; then
    echo "👤 Enabling lingering for user $USER..."
    loginctl enable-linger $USER
fi

# Create systemd user directory if it doesn't exist
mkdir -p ~/.config/systemd/user

# Get all containers with restart=always policy
containers=$(podman ps -a --format "{{.Names}}" --filter "restart-policy=always")

if [ -z "$containers" ]; then
    echo "❌ No containers found with restart=always policy"
    exit 1
fi

# Counter for successful setups
success_count=0

for container in $containers; do
    echo "🔧 Processing container: $container"
    
    # Generate systemd service file
    if podman generate systemd --name $container --files --new; then
        # Move service file to correct location
        mv container-$container.service ~/.config/systemd/user/
        
        # Reload systemd daemon
        systemctl --user daemon-reload
        
        # Enable and start the service
        if systemctl --user enable container-$container.service; then
            if systemctl --user start container-$container.service; then
                echo "✅ Successfully set up auto-restart for $container"
                ((success_count++))
            else
                echo "❌ Failed to start service for $container"
            fi
        else
            echo "❌ Failed to enable service for $container"
        fi
    else
        echo "❌ Failed to generate systemd service file for $container"
    fi
done

# Final status report
echo -e "\n📊 Summary:"
echo "Total containers processed: $(echo "$containers" | wc -w)"
echo "Successfully configured: $success_count"

# Verify lingering status
echo -e "\n📌 Lingering status:"
loginctl show-user $USER | grep Linger

echo -e "\n💡 To check service status for a container, use:"
echo "systemctl --user status container-<container_name>.service"

#!/bin/bash

set -e

# Run ifconfig command and filter eth0 line
mac_address=$(ifconfig eth0 | awk '/ether/ {gsub(/:/,"",$2); print $2}')

# Read the app version from the JSON file
app_version=$(jq -r '.version' ~/bundle/data/flutter_assets/version.json)
target_image="aircok/aircok_edge_app:${app_version}"

# Check if the Docker image exists
if ! sudo docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "$target_image"; then
  sudo docker pull "${target_image}"
  echo "✅ Downloaded '${target_image}' successfully."
fi

# Check if the Docker image exists locally
if ! sudo docker images | awk '{print $1}' | grep -q "$target_image"; then
    # Run Docker image
    sudo docker run -itd "$target_image"
    # Copy the app bundle from the Docker container
    container_id=$(sudo docker ps -aqf "$target_image")
    sudo docker cp "${container_id}:/app/AircokEdge/build/linux/x64/release/bundle" ~/
    # Stop the Docker container
    sudo docker stop "${container_id}"

    response=$(curl -X POST -H "Content-Type: application/json" -d "{\"app_version\": \"$app_version\"}" https://v3.aircok.com/web/edge/update?sn=$mac_address)
    if [[ "$response" != *"success"* ]]; then
        echo "⛔ Error: Request was not successful"
    else
        echo "✅ Successfully copied app bundle from '$target_image'"
    fi
fi

# Change directory to the app bundle
cd ~/AircokEdge/aircok_edge_app/bundle
# Run the app
./aircok_edge &
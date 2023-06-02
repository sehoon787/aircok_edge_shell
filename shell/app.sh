#!/bin/bash

set -e

# Read the versions from the JSON file
version_file=/home/aircok/version.json
db_version=$(jq -r '.db_version' "$version_file")
server_version=$(jq -r '.server_version' "$version_file")
app_version=$(jq -r '.app_version' "$version_file")
shell_version=$(jq -r '.shell_version' "$version_file")

# Run ifconfig command and filter eth0 line
mac_address=$(ifconfig eth0 | awk '/ether/ {gsub(/:/,"",$2); print $2}')

# Read the app version from the JSON file
version_file=/home/aircok/version.json
app_version=$(jq -r '.app_version' "$version_file")
target_image="aircok/aircok_edge_app:${app_version}"

# Check if the Docker image exists
if ! sudo docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "$target_image"; then
  sudo docker pull "${target_image}"
  echo "✅ Downloaded '${target_image}' successfully."
fi

# Check if the Docker image exists locally
if [[ -d /home/aircok/bundle && -f /home/aircok/bundle/version.json ]] || [[ $app_version != $(jq -r '.version' /home/aircok/bundle/version.json) ]]; then
    # Run Docker image
    sudo docker run -itd "$target_image"
    # Copy the app bundle from the Docker container
    container_id=$(sudo docker ps -qf "ancestor=$target_image")
	sudo docker cp "${container_id}":/app/AircokEdge/build/linux/arm64/release/bundle /home/aircok/
	
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
cd /home/aircok/bundle
# Run the app
./aircok_edge &
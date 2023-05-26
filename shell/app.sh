#!/bin/bash

set -e

# Read the app version from the JSON file
app_version=$(jq -r '.version' ~/bundle/data/flutter_assets/version.json)

# Check if the Docker image exists locally
if ! sudo docker images | awk '{print $1}' | grep -q "aircok/aircok_edge_app:${app_version}"; then
    # Run Docker image
    sudo docker run -itd "aircok/aircok_edge_app:${app_version}"
    # Copy the app bundle from the Docker container
    container_id=$(sudo docker ps -aqf "ancestor=aircok/aircok_edge_app:${app_version}")
    sudo docker cp "${container_id}:/app/AircokEdge/build/linux/x64/release/bundle" ~/
    # Stop the Docker container
    sudo docker stop "${container_id}"
    echo "✅ Successfully copied app bundle from 'aircok/aircok_edge_app:${app_version}'"
else
    # Change directory to the app bundle
    cd ~/AircokEdge/aircok_edge_app/bundle
    # Run the app
    ./aircok_edge
fi
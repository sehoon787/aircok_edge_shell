#!/bin/bash

set -e

# Read the versions from the JSON file
version_file=~/version.json
db_version=$(jq -r '.db_version' "$version_file")
version=$(jq -r '.version' "$version_file")
app_version=$(jq -r '.app_version' "$version_file")

# Define a list of Docker image names
DOCKER_IMAGES=(
  "aircok_edge_db${db_version}" 
  "aircok_edge${version}" 
  "aircok_edge_app${app_version}"
)

# Iterate over each Docker image name
for image_name in "${DOCKER_IMAGES[@]}"; do
    # Check if the Docker image exists on Docker Hub
    if sudo docker pull "${image_name}" &> /dev/null; then
        echo "Docker image '${image_name}' exists on Docker Hub."
        # Check if the Docker image already exists locally
        if sudo docker images | awk '{print $1":"$2}' | grep -q "${image_name}"; then
            echo "Docker image '${image_name}' is already present locally."
        else
            echo "Pulling the image..."
            # Remove previous version of the image if exists
            prev=$(sudo docker images --format "{{.Repository}}:{{.Tag}}" | grep "${image_name}")
            if [[ -n "$prev" ]]; then
                sudo docker rmi -f "$prev"
                echo "Previous version '$prev' has been forcefully removed."
            fi

            sudo docker pull "${image_name}"
            echo "✅ Downloaded '${image_name}' successfully..."
            sudo reboot
        fi
    else
        echo "Docker image '${image_name}' does not exist on Docker Hub."
        echo "⛔ Image not pulled."
    fi
done
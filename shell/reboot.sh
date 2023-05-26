#!/bin/bash

set -e

# Read the versions from the JSON file
version_file=~/version.json
db_version=$(jq -r '.db_version' "$version_file")
server_version=$(jq -r '.server_version' "$version_file")
app_version=$(jq -r '.app_version' "$version_file")
shell_version=$(jq -r '.shell_version' "$version_file")

# Define a list of Docker image names
DOCKER_IMAGES=(
  "aircok_edge_db${db_version}" 
  "aircok_edge${server_version}" 
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
            echo "✅ Downloaded '${image_name}' successfully."
        fi
    else
        echo "Docker image '${image_name}' does not exist on Docker Hub."
        echo "⛔ Image not pulled."
    fi
done

# Compare new shell version with current shell version 
cd ~/
sudo git clone https://github.com/aircok/aircok_edge_shell.git

new_shell_version=$(jq -r '.version' ~/aircok_edge_shell/version.json)

if [[ "$shell_version" == "$new_shell_version" ]]; then
  sudo rm -rf ~/aircok_edge_shell
else
  sudo rm -rf ~/shell
  sudo cp -R ~/aircok_edge_shell/shell ~/
  sudo rm -rf ~/aircok_edge_shell
  echo "✅ Update shell successfully."
fi

# Run ifconfig command and filter eth0 line
mac_address=$(ifconfig eth0 | awk '/ether/ {gsub(/:/,"",$2); print $2}')

response=$(curl -X POST -H "Content-Type: application/json" -d "{\"server_version\": \"$server_version\", \"app_version\": \"$app_version\", \"db\": \"$db_version\", \"shell\": \"$shell_version\"}" https://v3.aircok.com/web/edge/update?sn=$mac_address)
if [[ "$response" != *"success"* ]]; then
  echo "⛔ Error: Request was not successful"
  exit 1
else
  sudo reboot
fi
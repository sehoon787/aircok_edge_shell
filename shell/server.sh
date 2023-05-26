#!/bin/bash

set -e

# Run ifconfig command and filter eth0 line
mac_address=$(ifconfig eth0 | awk '/ether/ {gsub(/:/,"",$2); print $2}')

# Versions JSON file path
version_file=~/version.json

# Check broker.db
if [ -f "~/broker.db" ]; then
  sudo sqlite3 ~/broker.db "SELECT * FROM dvc_info;"
else
  # Read the versions from the JSON file
  db_version=$(jq -r '.db_version' "$version_file")
  # Run Docker image
  sudo docker run -itd "aircok/aircok_edge_db:${db_version}"
  # Copy the app bundle from the Docker container
  container_id=$(sudo docker ps -aqf "ancestor=aircok/aircok_edge_db:${db_version}")
  sudo docker cp "${container_id}:/broker.db" ~/
  # Stop the Docker container
  sudo docker stop "${container_id}"

  response=$(curl -X POST -H "Content-Type: application/json" -d "{\"db_version\": \"$db_version\"}" https://v3.aircok.com/web/edge/update?sn=$mac_address)
  if [[ "$response" != *"success"* ]]; then
      echo "⛔ Error: Request was not successful"
  else
    echo "✅ Successfully copied broker.db from 'aircok/aircok_edge_db:${db_version}'"
  fi
fi

# Check Docker network
if ! sudo docker network ls | grep edgenet; then
  echo "ℹ️ Creating 'edgenet' network..."
  sudo docker network create --subnet=192.168.10.0/24 --gateway=192.168.10.2 edgenet
  echo "✅ Created 'edgenet' successfully"
fi
ifconfig

# Check Docker logs volume
if ! sudo docker volume ls | grep logs; then
  echo "ℹ️ Creating logs volume..."
  sudo docker volume create logs
  echo "✅ Created logs volume successfully"
fi
echo "ℹ️ logs Volume info"
sudo docker volume inspect logs

# Check version
arch=$(dpkg --print-architecture)
server_version=$(jq -r '.version' "$version_file")
target_image="aircok/aircok_edge:${server_version}"

# Check if the Docker image exists
if ! sudo docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "$target_image"; then
  sudo docker pull "${target_image}"

  response=$(curl -X POST -H "Content-Type: application/json" -d "{\"server_version\": \"$server_version\"}" https://v3.aircok.com/web/edge/update?sn=$mac_address)
  if [[ "$response" != *"success"* ]]; then
      echo "⛔ Error: Request was not successful"
  else
      echo "✅ Downloaded '${target_image}' successfully."
  fi
fi

# Docker run
sudo docker run -d \
  --platform=linux/$arch \
  --network=edgenet --ip=192.168.10.1 \
  -p 8000:8000 \
  -v ~/broker.db:/db/broker.db \
  -v ~/logs:/app/logs \
  "$target_image"
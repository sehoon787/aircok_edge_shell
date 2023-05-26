#!/bin/bash

set -e

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
  echo "✅ Successfully copied broker.db from 'aircok/aircok_edge_db:${db_version}'"
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
version=$(jq -r '.version' "$version_file")

# Docker run
sudo docker run -d \
  --platform=linux/$arch \
  --network=edgenet --ip=192.168.10.1 \
  -p 8000:8000 \
  -v ~/broker.db:/db/broker.db \
  -v ~/logs:/app/logs \
  "aircok/aircok_edge:${version}"
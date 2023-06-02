#!/bin/bash

set -e

version_file=/home/aircok/version.json

# Read the versions from the JSON file
versions=(
    $(jq -r '.db_version' "$version_file")
    $(jq -r '.server_version' "$version_file")
    $(jq -r '.app_version' "$version_file")
    $(jq -r '.shell_version' "$version_file")
)
image_names=(
    "aircok/aircok_edge_db"
    "aircok/aircok_edge"
    "aircok/aircok_edge_app"
    $(jq -r '.version' /home/aircok/aircok_edge_shell/shell/version.json)
)

for i in "${versions[@]}"; do
    version=${versions[i]}
    image=${image_names[i]}

    image_tag=$(docker images --format "{{.Tag}}" "$image")

    if [[ "version" == "image_tag" ]]; then
        echo "true"
    else
        echo "false"
    fi
done
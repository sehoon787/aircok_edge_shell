#!/bin/bash

set -e

state="false"

version_file=/home/aircok/version.json

# Read the versions from the JSON file
versions=(
    "$(jq -r '.db_version' "$version_file")"
    "$(jq -r '.server_version' "$version_file")"
    "$(jq -r '.app_version' "$version_file")"
    "$(jq -r '.shell_version' "$version_file")"
)
image_names=(
    "aircok/aircok_edge_db"
    "aircok/aircok_edge"
    "aircok/aircok_edge_app"
    "aircok/aircok_edge_shell"
)

for i in "${!versions[@]}"; do
    version="${versions[$i]}"
    image="${image_names[$i]}"

    if [[ "$image" == *"aircok_edge_shell"* ]]; then
        image_tag="$(jq -r '.version' /home/aircok/aircok_edge_shell/shell/version.json)"
    else
        image_tag=$(sudo docker images --format "{{.Tag}}" "$image")
    fi


    if [[ "$version" != "$image_tag" ]]; then
        state="true"
        break
    fi
done

# Execute reboot shell
if [ "$state" = "true" ]; then
    bash /home/aircok/aircok_edge_shell/shell/reboot.sh
fi
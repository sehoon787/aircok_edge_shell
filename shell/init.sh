#!/bin/bash

set -e

# Update system packages
sudo apt-get update
sudo apt-get upgrade -y

# Install necessary packages
sudo apt-get install -y net-tools jq sqlite3 openssh-server git

# Allow SSH
sudo ufw allow ssh

# Install Docker engine
sudo apt-get install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Verify Docker installation
sudo docker version

# Install packages for Flutter HW acceleration
sudo apt-get install -y vlc libmpv-dev mpv

# Add a cron job to run the script at system reboot
(crontab -l 2>/dev/null; echo "@reboot /bin/bash ~/shell/start.sh") | crontab -
# Add a cron job to request check update per 6 hours
(crontab -l 2>/dev/null; echo "0 */6 * * * curl -o ~/version.json https://v3.aircok.com/web/edge/update") | crontab -

# Execute reboot script
bash ~/shell/reboot.sh
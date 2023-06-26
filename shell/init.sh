#!/bin/bash

set -e

# INIT
########################################################################
# Check broker.db
if ! [ -d /home/aircok/aircok_edge_shell/shell ]; then
    cd /home/aircok
    sudo git clone https://github.com/aircok/aircok_edge_shell.git
fi
sudo chmod 755 /home/aircok/aircok_edge_shell/shell/*

if command -v docker &> /dev/null; then
    echo "Docker command exists"
    # Stop all running containers
    container_ids=$(sudo docker ps -q)
    if [ -n "$container_ids" ]; then
        sudo docker stop $container_ids
        echo "Stopped all running Docker containers"
    fi
    # Clean up Docker system
    sudo docker system prune -a -f
fi
# Initialize Flutter
sudo rm -rf "/home/aircok/development"
sudo rm -rf "/home/aircok/bundle"
# Initialize FastAPI volumes
sudo rm -rf "/home/aircok/logs" 
sudo rm -f "/home/aircok/broker.db" 
# Initialize crontab
if sudo crontab -l &> /dev/null; then
    sudo crontab -r
fi
if sudo crontab -u aircok -l &> /dev/null; then
    sudo crontab -u aircok -r
fi
########################################################################

# Update system packages
sudo apt-get update
sudo apt-get upgrade -y

# Install necessary packages
sudo apt-get install -y net-tools jq sqlite3 openssh-server git curl

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

# Install Flutter
mkdir -p /home/aircok/development
cd /home/aircok/development
git clone https://github.com/flutter/flutter.git -b master 
cd flutter
git checkout 3.10.0-5.0.pre
sudo echo 'export PATH="$PATH:/home/aircok/development/flutter/bin"' | sudo tee -a /etc/profile
source /etc/profile
flutter doctor

# Get version.json from server
curl -o /home/aircok/version.json https://v3.aircok.com/web/edge/update?sn=$(ifconfig eth0 | awk '/ether/ {gsub(/:/,"",$2); print $2}')

# Add a cron job to request check update per 6 hours
(crontab -l 2>/dev/null; echo "0 */6 * * * sudo curl -o /home/aircok/version.json https://v3.aircok.com/web/edge/update?sn=\$(ifconfig eth0 | awk '/ether/ {gsub(/:/,\"\",$2); print \$2}')") | sudo crontab -
(crontab -l 2>/dev/null; echo "0 2 * * * bash /home/aircok/aircok_edge_shell/shell/listener.sh") | sudo crontab -

# Register start shell
sudo sh -c 'echo "#!/bin/bash\n\n/home/aircok/start.sh\n/home/aircok/aircok_edge_shell/shell/server.sh\n\nexit 0" > /etc/rc.local'

# Execute reboot shell
bash /home/aircok/aircok_edge_shell/shell/reboot.sh
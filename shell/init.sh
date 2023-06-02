#!/bin/bash

set -e

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

# Install Flutter to deal with 
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
(crontab -l 2>/dev/null; echo "0 */6 * * * curl -o /home/aircok/version.json https://v3.aircok.com/web/edge/update?sn=$(ifconfig eth0 | awk '/ether/ {gsub(/:/,"",$2); print $2}')") | crontab -
(crontab -l ; echo "0 2 * * * /home/aircok/aircok_edge_shell/shell/listener.sh") | crontab -

# Register start shell
sudo sh -c 'echo "#!/bin/bash\n\n/home/aircok/start.sh\n/home/aircok/aircok_edge_shell/shell/start.sh\n\nexit 0" >> /etc/rc.local'

# IP tunneling
sudo iptables -t nat -A PREROUTING -d 192.168.100.1 -j DNAT --to-destination 192.168.10.1

# Execute reboot script
bash /home/aircok/aircok_edge_shell/shell/reboot.sh
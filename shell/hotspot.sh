if [ -d /sys/class/net/wlx88366cfd5eed]; then
    # Create virtual interface
    iw devwlx88366cfd5eed interface add wlan1 type aircok_edge_app
    # Enable AP configuration, run
    nmcli con up WIFI_AP
fi
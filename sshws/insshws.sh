#!/bin/bash
# Link Hosting Kalian
sudo apt install python3

wget -O /usr/local/bin/ws "https://raw.githubusercontent.com/awanklod/os/main/sshws/ws"
chmod +x /usr/local/bin/ws

# Installing Service
cat > /etc/systemd/system/ws.service << END
[Unit]
Description=Proxy Mod By Newbie Store 
Documentation=https://t.me/newbie_store24
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/ws
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable ws.service
systemctl start ws.service
systemctl restart ws.service

wget -O /usr/local/bin/ws-ovpn "https://raw.githubusercontent.com/awanklod/os/main/sshws/ws"
chmod +x /usr/local/bin/ws-ovpn

# Installing Service
cat > /etc/systemd/system/ws-ovpn.service << END
[Unit]
Description=Proxy Mod By NEWBIE STORE
Documentation=https://t.me/newbie_store24
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/ws-ovpn 2086
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

systemctl daemon-reload
systemctl enable ws-ovpn
systemctl restart ws-ovpn


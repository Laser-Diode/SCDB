#!/bin/bash

output_seperator () {
   echo ""
   echo "========================================================="
   echo ""
}

conclude_install () {
   output_seperator
   echo "Device will restart in 15 seconds."
   sleep 10
   apt-get autoremove -y
   apt-get autoclean -y
   reboot
}

apt-get update && apt-get upgrade -y #update the raspberry pi device.
if (($? == 0)); then
   output_seperator
   echo "RPI updated"
else
   output_seperator
   echo "RPI could not be updated"
   exit 1
fi
output_seperator

apt-get install apache2 -y #install packages to enable access point.
if (($? == 0)); then
   output_seperator
   echo "apache2 installed"
else
   output_seperator
   echo "apache2 could not be installed"
   conclude_install
fi
output_seperator

service apache2 restart
mv /var/www/html/index.html /var/www/html/default.html
touch /var/www/html/index.html
echo "This is an example text file" > /var/www/html/example.txt
echo "echo 'This is an example bash script'" > /var/www/html/example.sh

echo "<html><head><title>Demo Site</title></head><body><h1>Demonstration Website</h1>" >> /var/www/html/index.html
echo "<p>This page exists at /var/www/html/index.html</p>" >> /var/www/html/index.html
echo "<p>To allow access to files place them in the /var/www/html/ directory</p>" >> /var/www/html/index.html
echo "<p>Here is an example: <a href=example.txt>.txt</a> and <a href=example.sh>.sh</a></p>" >> /var/www/html/index.html
echo "</body></html>" >> /var/www/html/index.html

output_seperator
echo "apache2 configured"
output_seperator

apt-get install hostapd dnsmasq -y #install packages to enable access point.
if (($? == 0)); then
   output_seperator
   echo "hostapd and dnsmasq installed"
else
   output_seperator
   echo "hostapd and dnsmasq could not be installed"
   conclude_install
fi
output_seperator

systemctl stop hostapd #stop the services while changes are being made
systemctl stop dnsmasq

output_seperator
echo "hostapd and dnsmasq services stopped (wireless ssh connection will be lost here)"
output_seperator

echo "interface wlan0" >> /etc/dhcpcd.conf
echo "    static ip_address=192.168.8.1/24" >> /etc/dhcpcd.conf
echo "    nohook wpa_supplicant" >> /etc/dhcpcd.conf

service dhcpcd restart

output_seperator
echo "dhcpcd configured"
output_seperator

mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
touch /etc/dnsmasq.conf
echo "interface=wlan0" >> /etc/dnsmasq.conf
echo "dhcp-range=192.168.8.2,192.168.8.20,255.255.255.0,24h" >> /etc/dnsmasq.conf
echo "address=/gw.wlan/192.168.8.1" >> /etc/dnsmasq.conf

systemctl start dnsmasq

output_seperator
echo "dnsmasq configured"
output_seperator

touch /etc/hostapd/hostapd.conf
echo "interface=wlan0" >> /etc/hostapd/hostapd.conf
echo "driver=nl80211" >> /etc/hostapd/hostapd.conf
echo "hw_mode=g" >> /etc/hostapd/hostapd.conf
echo "channel=7" >> /etc/hostapd/hostapd.conf
echo "wmm_enabled=0" >> /etc/hostapd/hostapd.conf
echo "macaddr_acl=0" >> /etc/hostapd/hostapd.conf
echo "auth_algs=1" >> /etc/hostapd/hostapd.conf
echo "ignore_broadcast_ssid=0" >> /etc/hostapd/hostapd.conf
echo "wpa=2" >> /etc/hostapd/hostapd.conf
echo "wpa_key_mgmt=WPA-PSK" >> /etc/hostapd/hostapd.conf
echo "wpa_pairwise=TKIP" >> /etc/hostapd/hostapd.conf
echo "rsn_pairwise=CCMP" >> /etc/hostapd/hostapd.conf
echo "ssid=SelfContainedDemoBox" >> /etc/hostapd/hostapd.conf
echo "wpa_passphrase=maycontainharmfulfiles" >> /etc/hostapd/hostapd.conf

echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' >> /etc/default/hostapd

systemctl unmask hostapd
systemctl enable hostapd
systemctl start hostapd

output_seperator
echo "hostapd configured"
output_seperator

systemctl status dnsmasq
systemctl status hostapd

output_seperator
echo "Service status checked"
output_seperator

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE
sh -c "iptables-save > /etc/iptables.ipv4.nat"
sed -i 's/exit 0$//' /etc/rc.local
echo "iptables-restore < /etc/iptables.ipv4.nat" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local

conclude_install

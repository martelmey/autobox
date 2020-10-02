#!/bin/bash

ARDUINO_TTY="/dev/ttyACM0"

###ACCESS
raspi-config
#enable VNC
systemctl enable --now ssh

cp /etc/wpa_supplicant/wpa_supplicant.conf cp /etc/wpa_supplicant/wpa_supplicant.conf.old
(
    echo "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev"
    echo "update_config=1"
    echo "country=CA" 
    echo "network={"
	echo '    ssid="RECKLESS_MXANALOG"'
	echo "    scan_ssid=1"
	echo '    psk=""'
	echo "    key_mgmt=WPA-PSK"
    echo "}"
)>/etc/wpa_supplicant/wpa_supplicant.conf

###UPDATES
apt upgrade
apt install python-serial iptables-persistent
pip install pyserial

###ARDUINO_COMMUNICATION (ACOM.PY)
(
    echo "import serial"
    echo "ser = serial.Serial('/dev/ttyACM0',9600)"
    echo "while True:"
	echo "    read_serial=ser.readline()"
	echo "    print(read_serial)"
)>/root/ACOM.py

###NET
hostnamectl set-hostname AB-CHURCHWOOD
iptables -P OUTPUT ACCEPT
iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
iptables -A INPUT -p tcp --dport 8088 -j ACCEPT
iptables -A INPUT -p tcp --dport 8089 -j ACCEPT
iptables -A INPUT -p tcp --dport 9997 -j ACCEPT
netfilter-persistent save

###SPLUNK UFW
wget -O splunkforwarder-8.0.6-152fb4b2bb96-Linux-x86_64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=8.0.6&product=universalforwarder&filename=splunkforwarder-8.0.6-152fb4b2bb96-Linux-x86_64.tgz&wget=true'
tar -zxvf splunkforwarder-8.0.6-152fb4b2bb96-Linux-x86_64.tgz -C /opt
useradd splunk -d /home/splunk
usermod -a -G root splunk
sed -i 's@PATH=$PATH:$HOME/.local/bin:$HOME/bin:/opt/splunk/bin@g' /home/splunk/.bash_profile
chown --recursive splunk:splunk /home/splunk/
chown --recursive splunk:splunk /opt/splunkforwarder/
su - splunk -c 'splunk start --accept-license --answer-yes'
su - splunk -c 'splunk add forward-server '
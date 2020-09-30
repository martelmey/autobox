#!/bin/bash

ARDUINO_TTY="/dev/ttyACM0"

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

apt upgrade
apt install python-serial
pip install pyserial

(
    echo "import serial"
    echo "ser = serial.Serial('/dev/ttyACM0',9600)"
    echo "while True:"
	echo "    read_serial=ser.readline()"
	echo "    print(read_serial)"
)>/root/arduino_communication.py
chmod +x arduino_communication.py
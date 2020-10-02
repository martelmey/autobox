#!/bin/bash

###start remote-exec
yum -y update
yum -y upgrade
yum -y install wget
systemctl enable --now firewalld
firewall-cmd --permanent --add-port=8000/tcp
firewall-cmd --permanent --add-port=8088/tcp
firewall-cmd --permanent --add-port=8089/tcp
firewall-cmd --permanent --add-port=9997/tcp
systemctl restart firewalld
useradd splunk -d /home/splunk
usermod -a -G root,wheel splunk
echo "PATH=$PATH:$HOME/.local/bin:$HOME/bin:/opt/splunk/bin" >> /home/splunk/.bash_profile
echo "export PATH" >> home/splunk/.bash_profile
source /home/splunk/.bash_profile
chown --recursive splunk:splunk /home/splunk/
wget -O splunk-8.0.6-152fb4b2bb96-Linux-x86_64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=8.0.6&product=splunk&filename=splunk-8.0.6-152fb4b2bb96-Linux-x86_64.tgz&wget=true'
tar -zxvf splunk-8.0.6-152fb4b2bb96-Linux-x86_64.tgz -C /opt
touch /opt/splunk/etc/system/local/user-seed.conf
(
    echo '[user_info]'
    echo 'USERNAME = splunkadmin'
    echo 'PASSWORD = '
)>/opt/splunk/etc/system/local/user-seed.conf
touch /opt/splunk/etc/splunk-launch.conf
(
    echo 'SPLUNK_SERVER_NAME=Splunkd'
    echo 'SPLUNK_OS_USER=splunk'
    echo 'SPLUNK_HOME=/opt/splunk'
)>/opt/splunk/etc/splunk-launch.conf
chown --recursive splunk:splunk /opt/splunk/
###end remote-exec
/opt/splunk/bin/./splunk start --answer-yes --accept-license
/opt/splunk/bin/./splunk enable boot-start -user splunk
/opt/splunk/bin/./splunk enable listen 9997
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
/opt/splunk/bin/./splunk enable deploy-server
###extra drive
mkfs -t xfs /dev/xvdf
mkdir /splunk-indexes
mount /dev/xvdf /splunk-indexes
cp /etc/fstab /etc/fstab.old
echo "UUID=547c8899-69ce-469a-8768-d3ee75b59f33  /splunk-indexes  xfs  defaults,nofail  0  2" >> /etc/fstab
chown --recursive splunk:splunk /splunk-indexes
###index creation
splunk add index autobox \
-homePath /splunk-indexes/autobox/db \
-coldPath /splunk-indexes/autobox/colddb \
-thawedPath /splunk-indexes/autobox/thawedDb \
-maxTotalDataSizeMB 20000
splunk add index autobox-met \
-homePath /splunk-indexes/autobox-met/db \
-coldPath /splunk-indexes/autobox-met/colddb \
-thawedPath /splunk-indexes/autobox-met/thawedDb \
-maxTotalDataSizeMB 20000
###apps&add-ons
sudo tar -zxvf splunk-add-on-for-infrastructure_220 -C /opt/splunk/etc/apps
sudo tar -zxvf splunk-app-for-infrastructure_220 -C /opt/splunk/etc/apps
sudo tar -zxvf splunk-add-on-for-infrastructure_220 -C /opt/splunk/etc/deployment-apps
sudo tar -zxvf splunk-add-on-for-unix-and-linux_820 -C /opt/splunk/etc/deployment-apps
sudo tar -zxvf metrics-add-on-for-infrastructure_103.tgz -C /opt/splunk/etc/deployment-apps
###apps&add-ons config
###Splunk_TA_nix
cp /opt/splunk/etc/deployment-apps/Splunk_TA_nix/default/inputs.conf /opt/splunk/etc/deployment-apps/Splunk_TA_nix/local/inputs.conf
sed -i 's@disabled = 1@disabled = 0@g' /opt/splunk/etc/deployment-apps/Splunk_TA_nix/local/inputs.conf
#add index = autobox-met
#add index = autobox
###TA-linux-metrics
cp /opt/splunk/etc/deployment-apps/TA-linux-metrics/default/inputs.conf /opt/splunk/etc/deployment-apps/TA-linux-metrics/local/inputs.conf
sed -i 's@disabled = 1@disabled = 0@g' /opt/splunk/etc/deployment-apps/TA-linux-metrics/local/inputs.conf
sed -i 's@index = metrics_linux@index = autobox-met@g' /opt/splunk/etc/deployment-apps/TA-linux-metrics/local/inputs.conf
###splunk_app_infrastructure
cp /opt/splunk/etc/apps/splunk_app_infrastructure/default/macros.conf /opt/splunk/etc/apps/splunk_app_infrastructure/local/macros.conf
#change index [sai_metrics_indexes] = index = autobox-met
#change index [sai_evnts_indexes] = index = autobox
chown --recursive splunk:splunk /opt/splunk
splunk reload deploy-server
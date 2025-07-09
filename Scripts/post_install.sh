#!/bin/bash
# build box with minimal with SSH port open

# su -
zypper in sudo vim
echo 'mansible  ALL=(ALL) NOPASSWD: ALL' | tee /etc/sudoers.d/mansible-nopasswd-all

# Use this pattern 
sudo zypper in -t pattern dhcp_dns_server

#### #### ####
## Setup BIND 
zypper in bind-utils
cp /etc/named.conf /etc/named.conf.$(date +%F)
# This is fugly
curl -o /etc/named.conf https://raw.githubusercontent.com/jradtke-suse/kubernerd.kubernerdes.lab/refs/heads/main/Files/backups/10.10.12.10/kubernerd.kubernerdes.lab/etc/named.conf

for FILE in kubernerdes.lab db-12.10.10.in-addr.arpa db-13.10.10.in-addr.arpa db-14.10.10.in-addr.arpa db-15.10.10.in-addr.arpa
do
  curl -o /var/lib/named/master/$FILE https://raw.githubusercontent.com/jradtke-suse/kubernerd.kubernerdes.lab/refs/heads/main/Files/backups/10.10.12.10/kubernerd.kubernerdes.lab/var/lib/named/master/$FILE
done
chown named:named /var/lib/named/master/*
systemctl enable named --now

#### #### ####
## Setup DHCP
cp /etc/dhcpd.conf /etc/dhcpd.conf.$(date +%F)
mkdir /etc/dhcpd.d/
curl -o /etc/dhcpd.conf https://raw.githubusercontent.com/jradtke-suse/kubernerd.kubernerdes.lab/refs/heads/main/Files/backups/10.10.12.10/kubernerd.kubernerdes.lab/etc/dhcpd.conf
curl -o /etc/dhcpd.d/dhcpd-hosts.conf https://raw.githubusercontent.com/jradtke-suse/kubernerd.kubernerdes.lab/refs/heads/main/Files/backups/10.10.12.10/kubernerd.kubernerdes.lab/etc/dhcpd.d/dhcpd-hosts.conf
sed -i -e 's/DHCPD_INTERFACE=""/DHCPD_INTERFACE="eth0"/g' /etc/sysconfig/dhcpd
systemctl enable dhcpd --now
systemctl status dhcpd

# Setup WWW server with PHP
suseconnect -p sle-module-web-scripting/15.6/x86_64
zypper install apache2 libyaml-devel
zypper install php8 apache2-mod_php8
php8 -v

sudo zypper addrepo https://download.opensuse.org/repositories/devel:languages:misc/SLE_15_SP4/devel:languages:misc.repo
sudo zypper refresh
sudo zypper install libyaml
sudo sed -i '965i extension=yaml.so' /etc/php8/apache2/php.ini

#### #### ####
## Install/configure SNMP
zypper install net-snmp
mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.$(date +%F)
curl -o /etc/snmp/snmpd.conf https:....
systemctl enable snmpd.service --now

#### #### ####
### Install kubectl
sudo tee /etc/zypp/repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repomd.xml.key
EOF
sudo zypper refresh

# Firewall
TCP_PORTS="53 80 443"
for PORT in $TCP_PORTS
do 
  firewall-cmd --permanent --zone=public --add-port=${PORT}/tcp
done

SERVICES="http https dns dhcp snmp"
for SERVICE in $SERVICES
do 
  firewall-cmd --permanent --zone=public --add-service=$SERVICE
done

firewall-cmd --reload
firewall-cmd --list-all

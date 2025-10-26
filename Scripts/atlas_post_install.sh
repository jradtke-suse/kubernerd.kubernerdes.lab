#!/bin/bash

# Atlas is the primary "infrastructure node" - it will run: bind, dhcp, tftp, http

# build box with minimal with SSH port open

# su -
zypper --non-interactive in sudo vim wget curlG
echo 'mansible  ALL=(ALL) NOPASSWD: ALL' | tee /etc/sudoers.d/mansible-nopasswd-all

# Use this pattern 
zypper --non-interactive in -t pattern dhcp_dns_server

#### #### ####
## Setup BIND 
zypper --non-interactive in bind-utils
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
suseconnect -p sle-module-web-scripting/15.7/x86_64
zypper --non-interactive install apache2 libyaml-devel
zypper --non-interactive install php8 apache2-mod_php8
php8 -v

sudo zypper addrepo https://download.opensuse.org/repositories/devel:languages:misc/SLE_15_SP4/devel:languages:misc.repo
sudo zypper refresh
sudo zypper --non-interactive install libyaml
sudo sed -i '965i extension=yaml.so' /etc/php8/apache2/php.ini

systemctl enable apache2.service --now

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
baseurl=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/repomd.xml.key
EOF
sudo zypper refresh
sudo zypper --non-interactive in kubectl

# Firewall
TCP_PORTS="53 80 443"
for PORT in $TCP_PORTS
do 
  firewall-cmd --permanent --zone=public --add-port=${PORT}/tcp
done
UDP_PORTS="67 68 69 4011"
for PORT in $UDP_PORTS
do
  firewall-cmd --permanent --zone=public --add-port=${PORT}/udp
done

SERVICES="http https dns dhcp snmp"
for SERVICE in $SERVICES
do 
  firewall-cmd --permanent --zone=public --add-service=$SERVICE
done

firewall-cmd --reload
firewall-cmd --list-all

zypper --non-interactive in lvm
pvcreate /dev/vdb
vgcreate vg_data /dev/vdb
lvcreate -l 100%FREE -n lv_data vg_data
mkdir /data
mkfs.ext4 /dev/mapper/vg_data-lv_data
sudo cp /etc/fstab /etc/fstab.orig-$(date +%F)
echo "/dev/mapper/vg_data-lv_data /data ext4 defaults 0 0" | sudo tee -a /etc/fstab
mkdir -p /data/srv/www/htdocs
echo "/data/srv/www/htdocs /srv/www/htdocs/ none bind,defaults 0 0" | sudo tee -a /etc/fstab
mount -a

cd /srv/www/htdocs
# TODO - need to figure out the correct URLs for these files
wget ./kubernerd.kubernerdes.lab/Files/backups/10.10.12.10/kubernerd.kubernerdes.lab/srv/www/htdocs/index.php

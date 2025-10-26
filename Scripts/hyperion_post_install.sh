#!/bin/bash

# Hyperion is the redundant DNS node, and Bastion for remote access
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
curl -o /etc/named.conf https://raw.githubusercontent.com/jradtke-suse/kubernerd.kubernerdes.lab/refs/heads/main/Files/backups/10.10.12.9/kubernerd.kubernerdes.lab/etc/named.conf

for FILE in kubernerdes.lab db-12.10.10.in-addr.arpa db-13.10.10.in-addr.arpa db-14.10.10.in-addr.arpa db-15.10.10.in-addr.arpa
do
  curl -o /var/lib/named/master/$FILE https://raw.githubusercontent.com/jradtke-suse/kubernerd.kubernerdes.lab/refs/heads/main/Files/backups/10.10.12.10/kubernerd.kubernerdes.lab/var/lib/named/master/$FILE
done
chown named:named /var/lib/named/master/*
systemctl enable named --now

#### #### ####
## Install/configure SNMP
zypper install net-snmp
mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.$(date +%F)
curl -o /etc/snmp/snmpd.conf https:....
systemctl enable snmpd.service --now

# Firewall
TCP_PORTS="53"
for PORT in $TCP_PORTS
do 
  firewall-cmd --permanent --zone=public --add-port=${PORT}/tcp
done

SERVICES="dns"
for SERVICE in $SERVICES
do 
  firewall-cmd --permanent --zone=public --add-service=$SERVICE
done

firewall-cmd --reload
firewall-cmd --list-all

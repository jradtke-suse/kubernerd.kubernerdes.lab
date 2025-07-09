#!/bin/bash

### YOOOO!  This is a very specific/opinionated script - it has NO other purpose
#            other than what I created it for.
#    TODO: Still need to add the HTTP files to be backed up

TARGET_ADDR=10.10.12.10
TARGET_USER=root # not awesome, but this is for a lab host
TARGET_BASEDIR="../Files/backups/${TARGET_ADDR}"

LOCAL_HOSTNAME=kubernerd.kubernerdes.lab

SOURCE_DIRECTORIES="
/etc/dhcpd.d/
/etc/dhcpd.conf
/etc/named.conf
/var/lib/named/master/
"
echo mkdir -p "${TARGET_BASEDIR}/${LOCAL_HOSTNAME}"

# The -R maintains the absolute path
for DIRECTORY in $SOURCE_DIRECTORIES
do
  echo "rsync -tugrpolvv -R ${TARGET_USER}@${TARGET_ADDR}:${DIRECTORY} ${TARGET_BASEDIR}/${LOCAL_HOSTNAME} "
  rsync -tugrpolvv -R ${TARGET_USER}@${TARGET_ADDR}:${DIRECTORY} ${TARGET_BASEDIR}/${LOCAL_HOSTNAME} 
done

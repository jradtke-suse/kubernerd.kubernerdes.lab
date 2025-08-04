#!/bin/bash -x
THISDATETIME=$(date +%F-%H-%M)

export OUTPUTDIR=/srv/www/htdocs/Comporium/$(date +%Y)/$(date +%m)/
[ ! -d ${OUTPUTDIR} ] && mkdir -p ${OUTPUTDIR}

export OUTPUTFILE=${OUTPUTDIR}/$(date +%F).html

create_header() {
cat << EOF | tee ${OUTPUTFILE}
<HTML>
<HEAD>
<TITLE>Comporium Uptime $(date +%F)</TITLE>
<META http-equiv="refresh" content="60; url=./$(date +%F).html">
</HEAD>
<BODY>
EOF
}
# If there is no file for TODAY, then create the HTML header
[ ! -f $OUTPUTFILE ] && create_header

ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1 && { echo "${THISDATETIME} | Success <BR>"; } || { echo "${THISDATETIME} | Fail <BR>"; } >> $OUTPUTFILE

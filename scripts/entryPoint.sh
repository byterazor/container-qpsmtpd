#!/bin/bash

#
# ensure some directories exist and have the correct access rights
#
mkdir -p /var/spool/qpsmtpd/karma 
chown -R smtpd:smtpd /var/spool/qpsmtpd

export QPSMTPD_plugin_dirs=/usr/share/qpsmtpd/plugins
export QPSMTPD_spool_dir=/var/spool/qpsmtpd

if [ -z ${QPSMTPD_plugins} ]; then
    echo "no plugins configuration available. Please provide one in QPSMTPD_plugins."
    exit 1
fi 

if [ -z ${QPSMTPD_PORT} ]; then
    QPSMTPD_PORT=25
fi

if [ -z ${QPSMTPD_CONCURRENT_CONNECTIONS} ]; then
    QPSMTPD_CONCURRENT_CONNECTIONS=15
fi

if [ -z ${QPSMTPD_MAX_FROM_IP} ]; then
    QPSMTPD_MAX_FROM_IP=5
fi

# start the forkserver of qpsmtpd
qpsmtpd-forkserver -p ${QPSMTPD_PORT} -c ${QPSMTPD_CONCURRENT_CONNECTIONS} -m ${QPSMTPD_MAX_FROM_IP}

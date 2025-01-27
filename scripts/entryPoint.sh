#!/bin/bash

#
# ensure some directories exist and have the correct access rights
#
mkdir -p /var/spool/qpsmtpd/karma 
chown -R smtpd:smtpd /var/spool/qpsmtpd


if [ -z ${QPSMTPD_PORT} ]; then
    QPSMTPD_PORT=25
fi

if [ -z ${QPSMTPD_CONCURRENT_CONNECTIONS} ]; then
    QPSMTPD_CONCURRENT_CONNECTIONS=15
fi

if [ -z ${QPSMTPD_MAX_FROM_IP} ]; then
    QPSMTPD_MAX_FROM_IP=5
fi

if [ -z ${QPSMTPD_LOGLEVEL} ]; then
    QPSMTPD_LOGLEVEL=3
fi

if [ -n "${QPSMTPD_RELAY}" ]; then
    rm -rf /etc/qpsmtpd/relayclients
    for i in ${QPSMTPD_RELAY}; do 
        echo $i >> /etc/qpsmtpd/relayclients
    done
fi

if [ -z  "${QPSMTPD_SMTP_RELAY_HOST}" ]; then
    echo "please provide QPSMTPD_SMTP_RELAY_HOST"
    exit 255
fi

if [ -n "${QPSMTPD_RECIPIENTS}" ]; then 
    rm -rf /etc/qpsmtpd/rcpthosts
    for i in ${QPSMTPD_RECIPIENTS}; do 
        echo $i >> /etc/qpsmtpd/rcpthosts
    done
fi



export QPSMTPD_CONFIG="/etc/qpsmtpd"

echo ${QPSMTPD_LOGLEVEL} > /etc/qpsmtpd/loglevel


#
# generate the plugins configuration file for qpsmtpd
#

if [ -n "${QPSMTPD_ENABLE_EARLYTALKER}" ]; then
    echo "earlytalker ${QPSMTPD_EARLYTALKER_PARAMS}"
fi

if [ -n "${QPSMTPD_ENABLE_TLS}" ]; then
    echo "tls" >> /etc/qpsmtpd/plugins
fi

echo "relay" >> /etc/qpsmtpd/plugins
echo "hosts_allow" >> /etc/qpsmtpd/plugins

echo "karma db_dir /var/spool/qpsmtpd/karma penalty_box 1 reject naughty" >> /etc/qpsmtpd/plugins
echo "fcrdns has_reverse_dns has_forward_dns reject naughty" >> /etc/qpsmtpd/plugins
echo "dnsbl reject naughty reject_type disconnect" >> /etc/qpsmtpd/plugins
echo "rhsbl" >> /etc/qpsmtpd/plugins 
echo "resolvable_fromhost reject naughty" >> /etc/qpsmtpd/plugins 
echo "bogus_bounce"  >> /etc/qpsmtpd/plugins 

#
# all recipient plugins
#

/plugins/rcpt_mysql

echo "rcpt_ok"    >> /etc/qpsmtpd/plugins    

#
# finish the configuration
#
echo "naughty reject data" >> /etc/qpsmtpd/plugins

#
# setup final queuing 
#
echo "queue/smtp-forward ${QPSMTPD_SMTP_RELAY_HOST}" 

# start the forkserver of qpsmtpd
qpsmtpd-forkserver -p ${QPSMTPD_PORT} -c ${QPSMTPD_CONCURRENT_CONNECTIONS} -m ${QPSMTPD_MAX_FROM_IP}

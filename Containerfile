FROM alpine:latest AS qpsmtpd-setup

RUN apk update && apk add --no-cache git

WORKDIR /tmp

# use the repository fork of byterazor because of reading config from environment variables
RUN git clone https://gitea.federationhq.de/byterazor/qpsmtpd.git
RUN cd /tmp/qpsmtpd;git checkout config

RUN git clone https://gitea.federationhq.de/byterazor/QPSMTPD-MailserverInterface.git
FROM debian:stable-slim

RUN apt-get update && apt-get -qy install perl-base tini bash

# qpsmtpd dependencies
RUN apt-get -qy install libnet-dns-perl libmime-base64-urlsafe-perl libtimedate-perl 
RUN apt-get -qy install libmailtools-perl libnet-ip-perl libdbd-mariadb-perl libdbd-mysql-perl 
RUN apt-get -qy install libclamav-client-perl cpanminus libmoose-perl


# qpsmtpd runs under the smtpd user
RUN adduser -u 34342 --disabled-login smtpd
RUN mkdir -p /usr/share/qpsmtpd

COPY --from=qpsmtpd-setup /tmp/qpsmtpd/qpsmtpd /usr/bin/
COPY --from=qpsmtpd-setup /tmp/qpsmtpd/qpsmtpd-forkserver /usr/bin/
COPY --from=qpsmtpd-setup /tmp/qpsmtpd/qpsmtpd-prefork /usr/bin/
COPY --from=qpsmtpd-setup /tmp/qpsmtpd/plugins /usr/share/qpsmtpd/plugins
COPY --from=qpsmtpd-setup /tmp/qpsmtpd/lib     /usr/share/perl5/ 
COPY --from=qpsmtpd-setup /tmp/QPSMTPD-MailserverInterface/federationhq_rcpt /usr/share/qpsmtpd/plugins/federationhq_rcpt
COPY --from=qpsmtpd-setup /tmp/QPSMTPD-MailserverInterface/clamdscan /usr/share/qpsmtpd/plugins/virus/clamdscan
COPY --from=qpsmtpd-setup /tmp/QPSMTPD-MailserverInterface/Net/LMTP.pm /usr/share/perl5/Net/LMTP.pm
COPY --from=qpsmtpd-setup /tmp/QPSMTPD-MailserverInterface/queue/lmtp /usr/share/qpsmtpd/plugins/queue/lmtp
RUN cpanm Net::ClamAV::Client 

# create spool directory
RUN mkdir -p /var/spool/qpsmtpd
RUN chown smtpd:smtpd /var/spool/qpsmtpd
RUN chmod 0700 /var/spool/qpsmtpd

ADD scripts/entryPoint.sh /entryPoint.sh
RUN chmod a+x /entryPoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/entryPoint.sh"]


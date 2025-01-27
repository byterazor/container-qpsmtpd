FROM alpine:latest AS qpsmtpd-setup

RUN apk update && apk add --no-cache git

WORKDIR /tmp

# use the repository fork of byterazor because of additional plugins
RUN git clone https://gitea.federationhq.de/byterazor/qpsmtpd.git
RUN cd /tmp/qpsmtpd;git checkout rcpt_mysql

FROM debian:stable-slim

RUN apt-get update && apt-get -qy install perl tini bash

# qpsmtpd dependencies
RUN apt-get -qy install libnet-dns-perl libmime-base64-urlsafe-perl libtimedate-perl 
RUN apt-get -qy install libmailtools-perl libnet-ip-perl libdbd-mariadb-perl libdbd-mysql-perl


# qpsmtpd runs under the smtpd user
RUN adduser -u 34342 --disabled-login smtpd
RUN mkdir -p /usr/share/qpsmtpd

COPY --from=qpsmtpd-setup /tmp/qpsmtpd/qpsmtpd /usr/bin/
COPY --from=qpsmtpd-setup /tmp/qpsmtpd/qpsmtpd-forkserver /usr/bin/
COPY --from=qpsmtpd-setup /tmp/qpsmtpd/qpsmtpd-prefork /usr/bin/
COPY --from=qpsmtpd-setup /tmp/qpsmtpd/plugins /usr/share/qpsmtpd/plugins
COPY --from=qpsmtpd-setup /tmp/qpsmtpd/lib     /usr/share/perl5/ 

# create spool directory
RUN mkdir -p /var/spool/qpsmtpd
RUN chown smtpd:smtpd /var/spool/qpsmtpd
RUN chmod 0700 /var/spool/qpsmtpd

# create base configuration
RUN mkdir -p /etc/qpsmtpd
COPY config /etc/qpsmtpd
RUN chown -R smtpd:smtpd /etc/qpsmtpd


ADD scripts/entryPoint.sh /entryPoint.sh
ADD scripts/plugins/ /plugins/
RUN chmod -R a+x /plugins/*
RUN chmod a+x /entryPoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/entryPoint.sh"]


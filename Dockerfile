FROM ubuntu:20.04
MAINTAINER Justin Henderson "justin@hasecuritysolutions.com"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

USER root

RUN debconf-set-selections <<< "postfix postfix/mailname string smtp.office365.com" && \
    debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'" && \
    apt-get update && \
    apt-get -q -y install postfix mailutils libsasl2-2 ca-certificates libsasl2-modules && \
    postconf -e smtpd_banner="\$myhostname ESMTP" && \
    postconf -e relayhost=[SMTP.office365.com]:587 && \
    postconf -e smtp_sasl_auth_enable=yes && \
    postconf -e smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd && \
    postconf -e smtp_sasl_security_options=noanonymous && \
    postconf -e smtp_tls_CAfile=/etc/postfix/cacert.pem  && \
    postconf -e smtp_use_tls=yes && \
    postconf -e soft_bounce=yes && \
    postconf -e smtp_header_checks=regexp:/etc/postfix/smtp_header_checks && \
    apt-get install -q -y \
    syslog-ng \
    syslog-ng-core && \
    sed -i -E 's/^(\s*)system\(\);/\1unix-stream("\/dev\/log");/' /etc/syslog-ng/syslog-ng.conf && \
    sed -i '/^smtp_tls_CAfile =/d' /etc/postfix/main.cf && \
    sed -i 's/^inet_protocols =.*/inet_protocols = ipv4/' /etc/postfix/main.cf && \
    apt-get install -q -y \
        supervisor

COPY supervisord.conf /etc/supervisor/
COPY init.sh /opt/init.sh

#>> Cleanup
RUN rm -rf /var/lib/apt/lists/* /tmp/* && \
apt-get autoremove -y && \
apt-get autoclean && \
ln -sf /dev/stdout /var/log/mail.log

EXPOSE 25

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

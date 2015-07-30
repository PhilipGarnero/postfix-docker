FROM debian:latest

# pre config to pass postfix install
RUN echo mail > /etc/hostname; \
    echo "postfix postfix/main_mailer_type string Internet site" > preseed.txt; \
    echo "postfix postfix/mailname string mail.example.com" >> preseed.txt \
    && debconf-set-selections preseed.txt

RUN apt-get update; apt-get install -y \
    mailutils \
    opendkim \
    opendkim-tools \
    postfix \
    postfix-mysql \
    rsyslog

RUN postconf -e smtpd_recipient_restrictions="permit_mynetworks"; \
    postconf -e smtpd_helo_restrictions="permit_mynetworks, reject_invalid_hostname, reject_non_fqdn_hostname"; \
    postconf -e milter_default_action="accept"; \
    postconf -e milter_protocol="2"; \
    postconf -e smtpd_milters="inet:localhost:8891"; \
    postconf -e non_smtpd_milters="inet:localhost:8891"; \
    mkdir -p /etc/postfix/dkim; \
    echo "Selector mail" >> /etc/opendkim.conf; \
    echo "KeyTable /etc/postfix/dkim/KeyTable" >> /etc/opendkim.conf; \
    echo "SigningTable /etc/postfix/dkim/SigningTable" >> /etc/opendkim.conf; \
    echo "ExternalIgnoreList /etc/postfix/dkim/TrustedHosts" >> /etc/opendkim.conf; \
    echo "InternalHosts /etc/postfix/dkim/TrustedHosts" >> /etc/opendkim.conf; \
    echo "Socket inet:8891@localhost" >> /etc/opendkim.conf; \
    echo "UserID opendkim:opendkim" >> /etc/opendkim.conf;

EXPOSE 25

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["start"]

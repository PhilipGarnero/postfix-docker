#!/bin/bash

set -e

if [ "$1" = 'start' ]; then
  postconf -e myhostname="$HOSTNAME"
  postconf -e mydestination="\$myhostname, localhost.\$mydomain, localhost"
  postconf -e virtual_alias_domains="$DOMAINS"

  echo "$HOSTNAME" > /etc/mailname
  echo "$HOSTNAME" > /etc/hostname

  if [ "${MYSQL_LOOKUP:-false}" = true ]; then
    postconf -e virtual_alias_maps="hash:/etc/postfix/virtual,mysql:/etc/postfix/virtual-aliases.cf"
    cat << EOF > /etc/postfix/virtual-aliases.cf
user = $MYSQL_ENV_MYSQL_USER
password = $MYSQL_ENV_MYSQL_PASSWORD
hosts = $MYSQL_PORT_3306_TCP_ADDR
dbname = $MYSQL_ENV_MYSQL_DATABASE
table = mailforwarding
select_field = real_email
where_field = fake_email
EOF
  else
    postconf -e virtual_alias_maps="hash:/etc/postfix/virtual"
  fi

  echo "" > /etc/postfix/virtual
  IFS=";"
  aliases=( $VIRTUAL_ALIASES )
  for alias in "${aliases[@]}"
    do echo $alias >> /etc/postfix/virtual
  done
  IFS=" "
  postmap /etc/postfix/virtual

  echo ">> starting the services"
  service rsyslog start
  service opendkim start
  service postfix start

  echo ">> printing the logs"
  touch /var/log/mail.log /var/log/mail.err /var/log/mail.warn
  chmod a+rw /var/log/mail.*
  tail -F /var/log/mail.*

elif [ "$1" = 'dkim-gen' ]; then
  mkdir -p /etc/postfix/dkim/keys
  cd /etc/postfix/dkim/keys

  echo "127.0.0.1" > /etc/postfix/dkim/TrustedHosts
  echo "localhost" >> /etc/postfix/dkim/TrustedHosts
  echo "" > /etc/postfix/dkim/KeyTable
  echo "" > /etc/postfix/dkim/SigningTable
  IFS=", "
  domains=($DOMAINS)
  for domain in "${domains[@]}"
    do opendkim-genkey -r -d $domain -s mail
    mv mail.txt $domain.txt
    mv mail.private $domain.key
    cat $domain.txt
    chown opendkim:opendkim $domain.key
    echo "mail._domainkey.$domain $domain:mail:/etc/postfix/dkim/keys/$domain.key" >> /etc/postfix/dkim/KeyTable
    echo "*@$domain mail._domainkey.$domain" >> /etc/postfix/dkim/SigningTable
  done
  IFS=" "

  cd -
else
  exec "$@"
fi

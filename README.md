postfix-docker
==============

Dockerized postfix installation with opendkim directed to virtual aliases


## Building the image

	$ sudo docker pull philipgarnero/postfix

## Usage
- Generate your dkim config

	```bash
	$ sudo docker run --rm -e DOMAINS="example.com test.com" \
	    -v /persistent/storage:/etc/postfix/dkim \
	    philipgarnero/postfix dkim-gen
	```

- Run postfix without mysql lookup

	```bash
	$ sudo docker run -p 25:25 --name postfix \
	    -v /persistent/storage:/etc/postfix/dkim \
	    -e DOMAINS="example.com test.com" \
	    -e HOSTNAME=example.com \
	    -e VIRTUAL_ALIASES="abuse@example.com you@mail.com;contact@test.com yourfriend@mail.com" \
	    -d philipgarnero/postfix
	```

- Run postfix with mysql lookup

	```bash
	$ sudo docker run -p 25:25 --name postfix \
	    -v /persistent/storage:/etc/postfix/dkim \
	    -e MYSQL_LOOKUP=true \
	    --link mysqlcontainer:mysql \
	    -e DOMAINS="example.com test.com" \
	    -e HOSTNAME=example.com \
	    -e VIRTUAL_ALIASES="abuse@example.com you@mail.com;contact@test.com yourfriend@mail.com" \
	    -d philipgarnero/postfix
	```

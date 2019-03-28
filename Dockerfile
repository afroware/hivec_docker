FROM ubuntu:14.04
 
LABEL maintainer="Adel Lamallam <lamallam@afroware.com>"

ARG user=afroware


ENV DEBIAN_FRONTEND noninteractive
ENV LETSENCRYPT_HOME /etc/letsencrypt
ENV DOMAINS ""
ENV WEBMASTER_MAIL ""

##Update server and install lamp server
RUN apt-get update \
	&& apt-get install dialog apt-utils -y \
    && apt-get install -q -y curl openssl apache2 \
    && a2enmod rewrite \
    && a2enmod headers \
	&& a2enmod ssl \
	&& a2enmod proxy \
	&& a2enmod proxy_http \
	&& a2enmod proxy_html \
	&& a2enmod xml2enc \
	&& a2enmod usertrack \
	&& a2enmod remoteip \
    && export LANG=en_US.UTF-8 \
    && apt-get install -y software-properties-common \
    && apt-get install -y language-pack-en-base \
    && LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php \
    && apt-get update \
	&& apt-get install -q -y  php5.6 php5.6-curl php5.6-intl php5.6-gd php5.6-dom php5.6-mcrypt php5.6-iconv php5.6-xsl php5.6-mbstring php5.6-ctype   php5.6-zip php5.6-pdo php5.6-xml php5.6-bz2 php5.6-calendar php5.6-exif php5.6-fileinfo php5.6-json php5.6-mysqli php5.6-mysql php5.6-posix php5.6-tokenizer php5.6-xmlwriter php5.6-xmlreader php5.6-phar php5.6-soap php5.6-mysql php5.6-fpm php5.6-bcmath libapache2-mod-php5.6 \
	&& DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-server-5.6 \
	&& apt-get install -y git nano curl openssh-server \
	&& apt-get install -y supervisor \
	&& apt-get clean \
	&& add-apt-repository ppa:certbot/certbot \
	&& apt-get -y update \
    && apt-get install -q -y python-certbot-apache \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
	
# configure apache
ADD config/mods-available/proxy_html.conf /etc/apache2/mods-available/
ADD config/conf-available/security.conf /etc/apache2/conf-available/
RUN echo "ServerName dardiafa.ma" >> /etc/apache2/conf-enabled/hostname.conf \	
	&& mkdir -p /var/lock/apache2 \
	&& mkdir -p /var/run/apache2



RUN sed -i -e"s/^memory_limit\s*=\s*128M/memory_limit = 512M/" /etc/php/5.6/apache2/php.ini \
	&& echo "date.timezone = Asia/Kolkata" >> /etc/php/5.6/apache2/php.ini \
	&& sed -i -e"s/^upload_max_filesize\s*=\s*2M/upload_max_filesize = 16M/" /etc/php/5.6/apache2/php.ini \
	&& sed -i -e"s/^max_execution_time\s*=\s*30/max_execution_time = 500/" /etc/php/5.6/apache2/php.ini \
	##setup non root user
	&& useradd -m -s /bin/bash ${user} \
	&& mkdir -p /home/${user}/www \
	##Download Qloapps latest version
	&& cd /home/${user}/www && git clone --branch v1.2.0 https://github.com/afroware/hivec.git \
	##change file permission and ownership
	&& find /home/${user}/www -type f -exec chmod 644 {} \; \
	&& find /home/${user}/www -type d -exec chmod 755 {} \; \
	&& chown -R ${user}: /home/${user}/www \
	&& sed -i "s@www-data@${user}@g" /etc/apache2/envvars \
	&& echo ' <Directory /home/> \n\
				Options FollowSymLinks \n\  
				Require all granted  \n\
				AllowOverride all \n\
				</Directory>  ' >> /etc/apache2/apache2.conf \
	##install supervisor and setup supervisord.conf file
	&& mkdir -p /var/log/supervisor \
	
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY update.sh /etc/update.sh
ADD config/scripts/run_letsencrypt.sh /etc/run_letsencrypt.sh
RUN chmod a+x /etc/update.sh && chmod a+x /etc/run_letsencrypt.sh
WORKDIR /home/${user}/www/hivec

EXPOSE 3306 80 443

CMD ["/usr/bin/supervisord"] 

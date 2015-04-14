FROM        ubuntu:15.04
MAINTAINER  Ross Riley "riley.ross@gmail.com"

# Install nginx
RUN apt-get update

RUN locale-gen en_US.UTF-8 && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale
RUN dpkg-reconfigure locales

#Install all the required packages
RUN apt-get -y install curl git nginx php5-fpm php5-pgsql php-apc php5-mcrypt php5-curl php5-gd php5-json php5-cli php5-sqlite libssh2-php supervisor cron

# Setup Nginx to run in non daemon mode
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# Setup PHP5 and modules along with composer binary
RUN sed -i -e "s/short_open_tag = Off/short_open_tag = On/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/post_max_size = 8M/post_max_size = 20M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/upload_max_filesize = 2M/upload_max_filesize = 20M/g" /etc/php5/fpm/php.ini
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# Configure nginx for PHP websites
RUN echo "cgi.fix_pathinfo = 0;" >> /etc/php5/fpm/php.ini
RUN echo "max_input_vars = 10000;" >> /etc/php5/fpm/php.ini
RUN echo "date.timezone = Europe/London;" >> etc/php5/fpm/php.ini

# Setup supervisor
RUN apt-get install -y supervisor cron
ADD supervisor/cron.conf /etc/supervisor/conf.d/
ADD supervisor/nginx.conf /etc/supervisor/conf.d/
ADD supervisor/php.conf /etc/supervisor/conf.d/
ADD supervisor/user.conf /etc/supervisor/conf.d/

# Disallow key checking
RUN echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config

# Adds the default server to nginx config
ADD config/nginx.conf /etc/nginx/sites-available/default

# Internal Port Expose
EXPOSE 80 443

ADD ./ /var/www/
CMD ["/usr/bin/supervisord", "-n"]

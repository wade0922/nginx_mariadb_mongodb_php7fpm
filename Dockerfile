#ubuntu 16.04
#mariadb
#mongodb
#nginx
#php7.0 fpm

FROM ubuntu:16.04

RUN apt-get update

RUN \
  apt-get install software-properties-common -y && \
  apt-get install vim -y 

#Mariadb
RUN apt-get install mariadb-server -y
RUN service mysql stop
RUN mysql_install_db
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
#RUN /etc/init.d/mysql start
RUN \ 
  /etc/init.d/mysql start && \
  mysql -u root -h localhost -e "update mysql.user set plugin = '', host = '%';"

#COPY 50-server.cnf /etc/mysql/mariadb.conf.d/
#RUN mysql -u root -e "update mysql.user set plugin = '';"

RUN service mysql restart

EXPOSE 3306

CMD ["mysqld"]

#MongoDB
RUN \
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 && \
  echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' > /etc/apt/sources.list.d/mongodb.list && \
  apt-get update && \
  apt-get install -y mongodb-org && \
  rm -rf /var/lib/apt/lists/*
# Define mountable directories.
VOLUME ["/data/db"]
# Define working directory.
WORKDIR /data
# Define default command.
CMD ["mongod"]
# Expose ports.
#   - 27017: process
#   - 28017: http
EXPOSE 27017
EXPOSE 28017

#Nginx
RUN apt-get update
RUN apt-get install nginx -y

# The default nginx.conf DOES NOT include /etc/nginx/sites-enabled/*.conf
COPY nginx.conf /etc/nginx/
COPY web1.conf /etc/nginx/sites-available/

# Solves 1
RUN mkdir -p /etc/nginx/sites-enabled/ \
    && ln -s /etc/nginx/sites-available/web1.conf /etc/nginx/sites-enabled/web1.conf 
RUN rm -r /etc/nginx/sites-enabled/default

# Solves 2
#RUN echo "upstream php-upstream { server php:9000; }" > /etc/nginx/conf.d/upstream.conf

# Solves 3
RUN usermod -u 1000 www-data

EXPOSE 80
EXPOSE 443

VOLUME ["/data/www"]

#PHP7
RUN \
  apt-get purge php5-fpm -y && \
  apt-get --purge autoremove -y  && \
  apt-get install php7.0-fpm php7.0-mysql php7.0-curl php7.0-gd php7.0-json php7.0-mcrypt php7.0-opcache php7.0-xml -y

COPY php.ini /etc/php/7.0/fpm/
COPY www.conf /etc/php/7.0/fpm/pool.d/

RUN \ 
  apt-get clean && \
  apt-get autoclean && \
  apt-get autoremove

CMD /etc/init.d/php7.0-fpm start && nginx -g "daemon off;"
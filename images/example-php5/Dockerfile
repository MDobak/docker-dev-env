FROM ubuntu:15.10

EXPOSE 80
VOLUME /var/www/html

RUN DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes install \
    php5 \
    apache2

# Configure env
USER root
ADD init/* /var/init/
RUN chmod 777 /var/init -R

# Init
USER root
CMD ["/var/init/init.sh"]

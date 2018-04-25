FROM ubuntu
RUN apt-get clean
RUN apt-get update
RUN apt-get -y dist-upgrade
RUN apt-get install -y supervisor python-pip libcapstone-dev mysql-client libmysqlclient-dev apache2 libapache2-mod-wsgi libapache2-mod-wsgi vim
RUN pip install --upgrade pip
COPY install/requirements.txt /tmp
RUN pip install -r /tmp/requirements.txt && rm /tmp/requirements.txt

RUN useradd -m -U -d /home/first -s /bin/bash first
COPY ./server /home/first
RUN chown first:first /home/first

COPY install/vhost.conf /etc/apache2/sites-available/first.conf

# This should be created and downloaded from
#   https://console.developers.google.com
COPY install/google_secret.json /usr/local/etc
# This should be created, a starting point can be found at
#   ./server/example_config.json
COPY install/first_config.json /home/first/first_config.json

RUN /usr/sbin/a2dissite 000-default
RUN /usr/sbin/a2ensite first
RUN /usr/sbin/a2enmod ssl
RUN /usr/sbin/a2enmod rewrite

# Set up supervisor
RUN mkdir -p /etc/supervisor/conf.d /var/log/supervisor
COPY install/supervisor/supervisord.conf /etc/supervisor/supervisord.conf

COPY install/supervisor/*.conf /etc/supervisor/conf.d/
RUN rm /etc/supervisor/conf.d/supervisord.conf

RUN mkdir /log


COPY install/run.sh /usr/local/bin
EXPOSE 80
EXPOSE 443
WORKDIR /home/first

VOLUME /log

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

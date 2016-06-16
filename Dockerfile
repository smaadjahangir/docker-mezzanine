#--------- Generic stuff all our Dockerfiles should start with so we get caching ------------
FROM debian:latest
MAINTAINER Tim Sutton<tim@linfiniti.com>

RUN  export DEBIAN_FRONTEND=noninteractive
ENV  DEBIAN_FRONTEND noninteractive
RUN  dpkg-divert --local --rename --add /sbin/initctl
#RUN  ln -s /bin/true /sbin/initctl

# Use local cached debs from host (saves your bandwidth!)
# Change ip below to that of your apt-cacher-ng host
# Or comment this line out if you do not with to use caching
ADD 71-apt-cacher-ng /etc/apt/apt.conf.d/71-apt-cacher-ng

RUN echo "deb http://httpredir.debian.org/debian jessie main" > /etc/apt/sources.list
#RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list
RUN apt-get -y update
RUN apt-get -y install ca-certificates openssh-server supervisor rpl pwgen
RUN mkdir /var/run/sshd
ADD sshd.conf /etc/supervisor/conf.d/sshd.conf

# Ubuntu 14.04 by default only allows non pwd based root login
# We disable that but also create an .ssh dir so you can copy
# up your key. NOTE: This is not a particularly robust setup 
# security wise and we recommend to NOT expose ssh as a public
# service.
RUN rpl "PermitRootLogin without-password" "PermitRootLogin yes" /etc/ssh/sshd_config
RUN mkdir /root/.ssh
RUN chmod o-rwx /root/.ssh

#-------------Application Specific Stuff ----------------------------------------------------
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get -y install nginx uwsgi uwsgi-plugin-python python-virtualenv vim
#RUN apt-get -y install nginx uwsgi uwsgi-plugin-python git python-virtualenv vim python-dev
RUN mkdir /home/web
ADD server-conf /home/web/server-conf
# Note that ww-data does not have permissions
# for the django project dir - so we will copy it over and then set the 
# permissions in teh start script
ADD django_project /tmp/django_project
ADD REQUIREMENTS.txt /home/web/REQUIREMENTS.txt
# Run any additional tasks here that are too tedious to put in
# this dockerfile directly.
ADD setup.sh /setup.sh
RUN chmod 0755 /setup.sh
RUN /setup.sh

# Called on first run of docker - will run supervisor
ADD start.sh /start.sh
RUN chmod 0755 /start.sh

CMD /start.sh


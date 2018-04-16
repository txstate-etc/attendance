FROM ubuntu:16.04

RUN apt-get update &&\
	apt-get upgrade -y &&\
	apt-get install software-properties-common -y &&\
	apt-add-repository ppa:brightbox/ruby-ng &&\
	apt-get update &&\
	apt-get install ruby1.9.3 git build-essential libz-dev libxml2-dev libmysqlclient-dev apache2 apache2-dev libcurl4-openssl-dev libssl-dev -y &&\
	gem install bundler

WORKDIR /tmp/docker

# two step copy is for faster rebuilds. bundle is only run when Gemfile changes
COPY Gemfile /tmp/docker/
RUN bundle install --without test development &&\
	/usr/local/bin/passenger-install-apache2-module -a

RUN apt-get install wget -y &&\
	wget https://raw.githubusercontent.com/txstate-etc/SSLConfig/master/SSLConfig-TxState.conf -O /etc/apache2/SSLConfig-TxState.conf

RUN mkdir -p /etc/pki/attendance &&\
	openssl genrsa -out /etc/pki/attendance/attendance.key.pem 4096 &&\
	openssl req -new -x509 -key /etc/pki/attendance/attendance.key.pem -out /etc/pki/attendance/attendance.cert.pem -sha256 -days 3650 -subj '/CN=localhost'

COPY . /tmp/docker/
RUN mkdir -p tmp/sessions &&\
	chown -R www-data /tmp/docker
COPY apache2.conf /etc/apache2/apache2.conf
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/apache2","-DFOREGROUND"]

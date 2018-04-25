FROM ubuntu:16.04

RUN apt-get update &&\
	apt-get upgrade -y &&\
	apt-get install tzdata locales -y &&\
	echo America/Chicago > /etc/timezone &&\
	ln -snf /usr/share/zoneinfo/`cat /etc/timezone` /etc/localtime &&\
	locale-gen en_US.UTF-8 &&\
	update-locale LANG=en_US.UTF-8 &&\
	apt-get install software-properties-common -y &&\
	apt-add-repository ppa:brightbox/ruby-ng &&\
	apt-get update &&\
	apt-get install wget ruby1.9.3 git build-essential libz-dev libxml2-dev libmysqlclient-dev apache2 apache2-dev libcurl4-openssl-dev libssl-dev -y &&\
	gem install bundler &&\
	wget https://raw.githubusercontent.com/txstate-etc/SSLConfig/master/SSLConfig-TxState.conf -O /etc/apache2/SSLConfig-TxState.conf &&\
	mkdir -p /ssl &&\
	openssl genrsa -out /ssl/localhost.key.pem 4096 &&\
	openssl req -new -x509 -key /ssl/localhost.key.pem -out /ssl/localhost.cert.pem -sha256 -days 3650 -subj '/CN=localhost'


WORKDIR /tmp/docker

# two step copy is for faster rebuilds. bundle is only run when Gemfile changes
COPY Gemfile /tmp/docker/
RUN bundle install --without test development &&\
	/usr/local/bin/passenger-install-apache2-module -a

COPY . /tmp/docker/
RUN rake assets:precompile

RUN mkdir -p tmp/sessions &&\
	chown -R www-data /tmp/docker

COPY apache2.conf /etc/apache2/apache2.conf
COPY entrypoint.sh /entrypoint.sh
COPY cmd.sh /cmd.sh


ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/apache2","-DFOREGROUND"]

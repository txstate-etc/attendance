FROM ubuntu:16.04

RUN apt-get update &&\
	apt-get upgrade -y &&\
	apt-get install software-properties-common -y &&\
	apt-add-repository ppa:brightbox/ruby-ng &&\
	apt-get update &&\
	apt-get install ruby1.9.3 git build-essential libz-dev libxml2-dev libmysqlclient-dev -y &&\
	gem install bundler

WORKDIR /tmp/docker

# two step copy is for faster rebuilds. bundle is only run when Gemfile changes
COPY Gemfile /tmp/docker/
RUN bundle install --without test development
COPY . /tmp/docker/

ENV DB_DATABASE=attendance DB_USER=attendance DB_HOST=mysql DB_PORT=3306

SHELL ["/bin/bash","-c"]
CMD ["rails","server","--port","80","--binding","0.0.0.0","--environment","production"]

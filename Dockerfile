FROM ubuntu:trusty
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt-get update -qq
RUN apt-get install -y build-essential libmysqlclient-dev curl

RUN curl -sSL https://get.rvm.io | bash
RUN source /etc/profile.d/rvm.sh
ENV PATH="${PATH}:/usr/local/rvm/bin"

RUN rvm install ruby-1.9.3-p392
RUN rvm ruby-1.9.3-p392@global --default --create

ENV PATH="${PATH}:/usr/local/rvm/rubies/ruby-1.9.3-p392/bin"

ENV APP_HOME /attendance
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

RUN gem install bundler

RUN apt-get install -y git libxml2-dev

ADD Gemfile* $APP_HOME/
RUN bundle install

ADD . $APP_HOME

CMD rails server --port 80 --binding 0.0.0.0

#!/bin/bash

export CAS_BASE_URL=${CAS_BASE_URL:-https://auth.yourinstitution.edu/cas/}
export WEB_HOSTNAME=${WEB_HOSTNAME:-`hostname`}

export DB_DATABASE=${DB_DATABASE:-attendance}
export DB_USER=${DB_USER:-attendance}
export DB_PASS=${DB_PASS:-}
export DB_HOST=${DB_HOST:-mysql}
export DB_PORT=${DB_PORT:-3306}

export CHECKIN_SECRET=${CHECKIN_SECRET:-`openssl rand -hex 64`}
export OAUTH_SECRET=${OAUTH_SECRET:-`openssl rand -hex 64`}

perl -i -pe 's/\Q{{CAS_BASE_URL}}\E/$ENV{CAS_BASE_URL}/' /tmp/docker/config/application.rb
perl -i -pe 's/\Q{{WEB_HOSTNAME}}\E/$ENV{WEB_HOSTNAME}/' /etc/apache2/apache2.conf

perl -i -pe 's/\Q{{DB_DATABASE}}\E/$ENV{DB_DATABASE}/' /tmp/docker/config/database.yml
perl -i -pe 's/\Q{{DB_USER}}\E/$ENV{DB_USER}/' /tmp/docker/config/database.yml
perl -i -pe 's/\Q{{DB_PASS}}\E/$ENV{DB_PASS}/' /tmp/docker/config/database.yml
perl -i -pe 's/\Q{{DB_HOST}}\E/$ENV{DB_HOST}/' /tmp/docker/config/database.yml
perl -i -pe 's/\Q{{DB_PORT}}\E/$ENV{DB_PORT}/' /tmp/docker/config/database.yml

perl -i -pe 's/\Q{{CHECKIN_SECRET}}\E/$ENV{CHECKIN_SECRET}/' /tmp/docker/config/initializers/checkin_token.rb
perl -i -pe 's/\Q{{OAUTH_SECRET}}\E/$ENV{OAUTH_SECRET}/' /tmp/docker/config/initializers/oauth_secret.rb

exec "$@"

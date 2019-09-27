#!/bin/bash

export CAS_BASE_URL=${CAS_BASE_URL:-http://localhost:2000/}
export CAS_VALIDATE_URL=${CAS_VALIDATE_URL:-http://fakecas/serviceValidate}
export WEB_HOSTNAME=${WEB_HOSTNAME:-`hostname`}

export DB_DATABASE=${DB_DATABASE:-attendance}
export DB_USER=${DB_USER:-root}
export DB_PASS=${DB_PASS:-}
export DB_HOST=${DB_HOST:-mysql}
export DB_PORT=${DB_PORT:-3306}

export CHECKIN_SECRET=${CHECKIN_SECRET:-`openssl rand -hex 64`}
export OAUTH_SECRET=${OAUTH_SECRET:-`openssl rand -hex 64`}

perl -i -pe 's/\Q{{CAS_BASE_URL}}\E/$ENV{CAS_BASE_URL}/' /usr/app/config/application.rb
perl -i -pe 's/\Q{{CANVAS_API_BASE}}\E/$ENV{CANVAS_API_BASE}/' /usr/app/config/application.rb
perl -i -pe 's/\Q{{CANVAS_API_TOKEN}}\E/$ENV{CANVAS_API_TOKEN}/' /usr/app/config/application.rb
perl -i -pe 's/\Q{{CAS_VALIDATE_URL}}\E/$ENV{CAS_VALIDATE_URL}/' /usr/app/config/application.rb
perl -i -pe 's/\Q{{WEB_HOSTNAME}}\E/$ENV{WEB_HOSTNAME}/' /etc/apache2/apache2.conf

perl -i -pe 's/\Q{{DB_DATABASE}}\E/$ENV{DB_DATABASE}/' /usr/app/config/database.yml
perl -i -pe 's/\Q{{DB_USER}}\E/$ENV{DB_USER}/' /usr/app/config/database.yml
perl -i -pe 's/\Q{{DB_PASS}}\E/$ENV{DB_PASS}/' /usr/app/config/database.yml
perl -i -pe 's/\Q{{DB_HOST}}\E/$ENV{DB_HOST}/' /usr/app/config/database.yml
perl -i -pe 's/\Q{{DB_PORT}}\E/$ENV{DB_PORT}/' /usr/app/config/database.yml

perl -i -pe 's/\Q{{CHECKIN_SECRET}}\E/$ENV{CHECKIN_SECRET}/' /usr/app/config/initializers/checkin_token.rb
perl -i -pe 's/\Q{{OAUTH_SECRET}}\E/$ENV{OAUTH_SECRET}/' /usr/app/config/initializers/oauth_secret.rb

perl -i -pe 's/\Q{{sslkeyfile}}\E/glob("\/ssl\/*.key.pem")/e' /etc/apache2/apache2.conf
perl -i -pe 's/\Q{{sslcertfile}}\E/glob("\/ssl\/*.cert.pem")/e' /etc/apache2/apache2.conf

exec "$@"

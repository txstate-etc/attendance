Attendance Install
===============

#### This procedure was used to setup the attendance staging environment on RHEL 6.3 server on 7/31/2012. 
#### It may prove useful for setting up on a development or production environment as well.

# software installed
* EPEL yum repository, for libyaml
* build tools (for rvm to compile ruby, mainly)
* apache
* mysql
* rvm
* ruby 1.9.3 in rvm
* passenger
* git (for pulling down our source code)
* our source code: https://github.com/txstate-etc/attendance.git

# configuration
* set apache and mysql to run at boot
* add user 'rubyapps'. All ruby apps will run from his home dir, with his instance of rvm. apache user needs access to his home dir.
* put ssh public key for builder in /home/rubyapps/.ssh/authorized_keys so that builder can run the deploy script
   (put any other keys here for others to run the deploy script as well)
* after checking out the attendance source, create tmp directory
* mysql root pw: (in /home/rubyapps/mysqlpw)
* mysql: create database 'attendance_staging', user 'attendance' with full privileges on that db, pw: (in /home/rubyapps/mysqlpw)
* configure apache to run rails apps with passenger
* create virtual host for 'attendance' in apache configs. See below.
* disable SELINUX

# commands as typed
  sudo rpm -Uvh http://www.gtlib.gatech.edu/pub/fedora-epel/6/i386/epel-release-6-8.noarch.rpm

  sudo yum install gcc gcc-c++ patch readline readline-devel zlib \
    zlib-devel libyaml-devel libxml2-devel libxslt-devel libffi-devel openssl-devel make bzip2 \
    autoconf automake libtool bison iconv-devel httpd httpd-devel mercurial \
    mysql mysql-server mysql-devel curl-devel git mod_ssl

  sudo nano /etc/selinux/config (set SELINUX=disabled) 
  sudo setenforce 0 (this disables selinux until next reboot)
    
  sudo service httpd start
  sudo chkconfig --level 35 httpd on

  sudo service mysqld start
  sudo chkconfig --level 35 mysqld on
  sudo /usr/bin/mysql_secure_installation
  # set a random password and store it in /home/rubyapps/mysqlpw after you create rubyapps user

  sudo nano /etc/sysconfig/iptables
  # opened port 80 for http traffic
  sudo service iptables restart

  sudo useradd rubyapps
  sudo usermod -aG apache rubyapps
  sudo chmod 711 /home/rubyapps
  sudo su - rubyapps
  cd ~

  nano mysqlpw # put your random password from earlier in here

  mysql -u root -pyourpassword -e "CREATE DATABASE attendance_staging; GRANT ALL PRIVILEGES ON attendance_staging.* TO attendance@localhost IDENTIFIED BY '<password>'" 

  echo 'install: --no-rdoc --no-ri' >> ~/.gemrc
  echo 'update: --no-rdoc --no-ri' >> ~/.gemrc

  curl -L https://get.rvm.io | bash -s stable
  source /home/rubyapps/.rvm/scripts/rvm
  rvm install 1.9.3-p392
  rvm --default use 1.9.3-p392
  rvm gemset create attendance

  mkdir -p /home/rubyapps/attendance/shared/tmp/sessions
  mkdir -p /home/rubyapps/attendance/shared/config/initializers
  nano /home/rubyapps/attendance/shared/config/initializers/auth.rb (see below)
  nano /home/rubyapps/attendance/shared/config/initializers/oauth_secret.rb (see below)
  # key should match the key set up for TRACS, 'test123' is just for staging

  rvm 1.9.3-p392@global
  gem install passenger
  passenger-install-apache2-module

  exit

  sudo chgrp -R apache /home/rubyapps/attendance
  sudo chmod -R g+s /home/rubyapps/attendance
  sudo nano /etc/httpd/conf/httpd.conf (comment out DocumentRoot)
  sudo nano /etc/httpd/conf.d/passenger.conf (see below)
  sudo nano /etc/httpd/conf.d/attendance.conf (see below)
  sudo nano /etc/httpd/conf.d/attendance_vhost.conf (see below)

  # for SSL setup
  sudo mkdir /home/rubyapps/ssl
  sudo nano /home/rubyapps/ssl/star_txstate_edu.crt
  # paste in the certificate
  sudo nano /home/rubyapps/ssl/DigiCertCA.crt
  # paste in the certificate chain
  sudo nano /home/rubyapps/ssl/private.key
  # paste in the key used to generate the CSR

  sudo service httpd reload

  sudo nano /etc/logrotate.d/attendance (see below)

  # put your public key in ~rubyapps/.ssh/authorized_keys
  sudo mkdir /home/rubyapps/.ssh
  sudo chmod 700 /home/rubyapps/.ssh
  sudo nano /home/rubyapps/.ssh/authorized_keys
  # paste your key
  sudo chmod 600 /home/rubyapps/.ssh/authorized_keys

  # run the following on your local machine:
  cap production deploy:setup
  cap production deploy
    
# /etc/httpd/conf.d/passenger.conf
  LoadModule passenger_module /home/rubyapps/.rvm/gems/ruby-1.9.3-p392@global/gems/passenger-4.0.10/buildout/apache2/mod_passenger.so
  PassengerRoot /home/rubyapps/.rvm/gems/ruby-1.9.3-p392@global/gems/passenger-4.0.10
  PassengerDefaultRuby /home/rubyapps/.rvm/wrappers/ruby-1.9.3-p392@global/ruby

# /etc/httpd/conf.d/attendance_vhost.conf
  ServerName attendance.staging.its.txstate.edu
  DocumentRoot /home/rubyapps/attendance/current/public
  RailsEnv staging
  PassengerMaxPoolSize 8

  <Directory /home/rubyapps/attendance/current/public>
    AllowOverride all
    Options -MultiViews
  </Directory>

  # Enable far-future caching for files in the assets directory
  <LocationMatch "^/assets/.*$">
    Header unset ETag
    FileETag None
    # RFC says only cache for 1 year
    ExpiresActive On
    ExpiresDefault "access plus 1 year"
  </LocationMatch>

  # Let apache serve the pre-compiled .gz version of static assets,
  # if available, and the user-agent can handle it. Set all headers
  # correctly when doing so.
  <LocationMatch "^/assets/.*\.(css|js)$">
    RewriteEngine on

    # Make sure the browser supports gzip encoding before we send it,
    # and that we have a precompiled .gz version.
    RewriteCond %{HTTP:Accept-Encoding} \b(x-)?gzip\b
    RewriteCond %{REQUEST_FILENAME}.gz -s
    RewriteRule ^(.+)$ $1.gz
  </LocationMatch>

  # Make sure Content-Type is set for 'real' type, not gzip,
  # and Content-Encoding is there to tell browser it needs to
  # unzip to get real type.
  #
  # Make sure Vary header is set; while apache docs suggest it
  # ought to be set automatically by our RewriteCond that uses an HTTP
  # header, does not seem to be reliably working.
  <LocationMatch "^/assets/.*\.css\.gz$">
    ForceType text/css
    Header set Content-Encoding gzip
    Header add Vary Accept-Encoding
  </LocationMatch>

  <LocationMatch "^/assets/.*\.js\.gz$">
    ForceType application/javascript
    Header set Content-Encoding gzip
    Header add Vary Accept-Encoding
  </LocationMatch>

  LimitRequestBody 15728640
  ErrorDocument 413 /413.html

  ErrorLog logs/attendance.error.log
  LogLevel warn
  CustomLog logs/attendance.access.log combined
  ServerSignature Off

# /etc/httpd/conf.d/attendance.conf
  TraceEnable Off

  <VirtualHost *:80>
    include conf.d/attendance_vhost.conf
  </VirtualHost>
  <VirtualHost *:443>
    include conf.d/attendance_vhost.conf

    SSLEngine On
    SSLCertificateFile /home/rubyapps/ssl/star_txstate_edu.crt
    SSLCertificateKeyFile /home/rubyapps/ssl/private.key
    SSLCertificateChainFile /home/rubyapps/ssl/DigiCertCA.crt       
  </VirtualHost>

# /home/rubyapps/attendance/shared/config/initializers/auth.rb
  MYSQL_USER = 'attendance' unless defined? MYSQL_USER
  MYSQL_PASSWORD = '<password>' unless defined? MYSQL_PASSWORD
    
# /home/rubyapps/attendance/shared/config/initializers/oauth_secret.rb
  Attendance::Application.config.oauth_secret = 'test123'

# /etc/logrotate.d/attendance
  /home/rubyapps/attendance/current/log/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
  }

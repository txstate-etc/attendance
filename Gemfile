source 'https://rubygems.org'

gem 'rails', '3.2.13'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'mysql2', '>= 0.3.16'

gem 'oauth'
gem 'ims-lti'

gem 'libxml-ruby'

gem 'composite_primary_keys'

group :development, :test do
  gem 'debugger'
  gem 'timecop'
end

gem 'rubycas-client', '~> 2.3.9.rc1'
gem 'rubycas-client-rails', :git => 'git://github.com/wickning1/rubycas-client-rails.git'
gem 'font-awesome-sass', '~> 4.6.2'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'jquery-ui-rails'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', '>= 0.12.1', :platforms => :ruby 

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails', '>= 3.0.4'

group :development do
	gem 'thin'
	gem 'capistrano'
	gem 'capistrano-ext'
	gem 'rvm-capistrano', require: false
	#gem 'rack-mini-profiler'
end

# Cron jobs, e.g., cache cleanup
gem "whenever"

# for per-request caching in static methods
gem 'request_store'

# serve static pages
gem "high_voltage"

# sends you an email when an exception occurs
gem 'exception_notification'

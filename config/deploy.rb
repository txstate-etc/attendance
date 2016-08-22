#
# Pull in recipes from external libraries
#

set :stages, %w(production staging)
# Don't default the stage. Make sure people really know what command they are running.
#set :default_stage, "staging"
require 'capistrano/ext/multistage'

set :rvm_ruby_string, ENV['GEM_HOME'].gsub(/.*\//,"")
set :rvm_install_type, :head # always install the latest (unreleased) version of rvm
# Update rvm and ruby on every deploy. If you run another capistrano command
# and get an error about ruby not being installed, 
# run `cap rvm:install_rvm rvm:install_ruby` manually.
before 'deploy:update_code', 'rvm:install_rvm'   # install RVM
before 'deploy:update_code', 'rvm:install_ruby'  # install Ruby and create gemset
require "rvm/capistrano"

require "bundler/capistrano"

set :whenever_command, "bundle exec whenever"
set :whenever_environment, defer { stage }
set :whenever_identifier, defer { "#{application}_#{stage}" }
require "whenever/capistrano"

# define a method to run rake tasks
def run_rake(task, options={}, &block)
  rake = fetch(:rake, 'rake')
  rails_env = fetch(:rails_env, 'production')

  command = "cd #{current_path} && #{rake} #{task} RAILS_ENV=#{rails_env}"
  run(command, options, &block)
end

# define a method to run rake tasks
def local_rake(task, options={}, &block)
  rake = fetch(:rake, 'rake')
  command = "#{rake} #{task}"
  system(command, options, &block)
end

#
# Set up configuration variables (environment specific stuff is in deploy/#{stage}.rb)
#

set :application, "attendance"
set :repository,  "https://github.com/txstate-etc/#{application}"
set :branch, ENV['BRANCH'] if ENV['BRANCH']
set :user, "rubyapps"
set :deploy_to, "/home/#{user}/#{application}"
set :scm, :git
set :use_sudo, false


#
# Recipes to run before/after deployment
#

# delete all but the 5 most recent releases
after "deploy:restart", "deploy:cleanup"

# create symlinks to shared files
after "deploy:update_code", "config:symlinks", "tmp:symlinks"

# generate static html files
after "deploy:create_symlink", "static:generate", "static:symlinks"

# precompile assets (must be done after symlinks are created)
load 'deploy/assets'

#
# Custom recipe definitions
#

# Passenger restart command:
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

namespace :config do
  desc "Make symlink for the auth file" 
  task :symlinks do
    run "ln -nfs #{shared_path}/config/initializers/auth.rb #{release_path}/config/initializers/auth.rb" 
    run "ln -nfs #{shared_path}/config/initializers/oauth_secret.rb #{release_path}/config/initializers/oauth_secret.rb"
    run "ln -nfs #{shared_path}/config/initializers/checkin_token.rb #{release_path}/config/initializers/checkin_token.rb"
    run "ln -nfs #{shared_path}/config/initializers/tracs_user.rb #{release_path}/config/initializers/tracs_user.rb"
  end
end

namespace :tmp do
  desc "Make symlink for the sessions directory" 
  task :symlinks do
    run "ln -nfs #{shared_path}/tmp/sessions #{release_path}/tmp/sessions" 
  end
end

namespace :static do
  desc "Generate static html files and put them in /public/" 
  task :generate do
    run_rake 'static:generate'
  end
  desc "Make symlinks for site-defined files that go in /public/" 
  task :symlinks do
    run "ln -nfs #{shared_path}/public/robots.txt #{release_path}/public/robots.txt" 
  end
end

namespace :data do
  set :sql_dump_file, "dump.#{application}.sql"
  
  desc "Export data from the target environment and copy it to the local environment"
  task :import do
    create_dump
    xfer_dump
    load_dump
  end
  
  task :importlast do
    xfer_dump
    load_dump
  end
  
  task :grab_dump do
    create_dump
    xfer_dump
  end
  
  desc "Create sql file on remote server via rake task"
  task :create_dump, :roles => :db, :only => { :primary => true } do
    on_rollback { run "rm #{current_path}/tmp/#{sql_dump_file}" }

    logger.debug "executing remote mysqldump"
    run_rake 'db:dump'
  end
  
  desc "Move sql file from remote to local"
  task :xfer_dump do
    logger.debug "initiating transfer"
    get "#{current_path}/tmp/#{sql_dump_file}", "tmp/#{sql_dump_file}"
    run "rm #{current_path}/tmp/#{sql_dump_file}"
  end

  desc "Load local sql file into local database"
  task :load_dump do
    if File.exist?("tmp/#{sql_dump_file}") 
      logger.debug "importing into local database"
      local_rake 'db:fromdump'
      local_rake 'db:migrate'
      if Capistrano::CLI.ui.agree("Delete local dump file? (y/n) ", true)
        FileUtils.rm_rf("tmp/#{sql_dump_file}")
      else
        FileUtils.mv("tmp/#{sql_dump_file}", "tmp/"+Time.now.strftime("%Y%m%d%H%M%S")+".#{sql_dump_file}")
      end
    else
      abort "No dump file exists, try data:import or data:importlast instead"
    end
  end
  
  desc "Assume we have a local dump file and send it to staging"
  task :send_dump do
    logger.debug "uploading dump file to remote server"
    upload "tmp/#{sql_dump_file}", "#{current_path}/tmp/#{sql_dump_file}"
    logger.debug "importing into remote database"
    run_rake 'db:fromdump'
    run "rm #{current_path}/tmp/#{sql_dump_file}"
    run_rake 'db:migrate'
  end
  
end

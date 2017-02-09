namespace :db do
  desc "Dump mysql data to file."
  task :dump => :environment do
    config = Rails.configuration.database_configuration[Rails.env]
    `mysqldump -h #{config['host']||'localhost'} --port #{config['port']||'3306'} -u #{config['username']} --password=#{config['password']} #{config['database']} > #{Rails.root}/tmp/dump.attendance.sql`
  end

  desc "Import mysql data from file."
  task :fromdump => :environment do
    if (Rails.env == "production")
      puts "Never run this in production!"
    else
      config = Rails.configuration.database_configuration[Rails.env]
      `mysql -h #{config['host']||'localhost'} --port #{config['port']||'3306'}  -u #{config['username']} --password=#{config['password']} -e "DROP DATABASE IF EXISTS #{config['database']}; CREATE DATABASE #{config['database']}"`
      `mysql -h #{config['host']||'localhost'} --port #{config['port']||'3306'}  -u #{config['username']} --password=#{config['password']} #{config['database']} < #{Rails.root}/tmp/dump.attendance.sql`
    end
  end
end

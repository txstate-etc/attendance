namespace :db do
  desc "Convert specific tables to UTF8 to support special characters."
  task :utf8 => :environment do
    puts "converting tables to utf8"
    config = Rails.configuration.database_configuration[Rails.env]
    r = ActiveRecord::Base.connection.execute("SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, C.CHARACTER_SET_NAME
      FROM information_schema.TABLES AS T
      JOIN information_schema.COLUMNS AS C USING (TABLE_SCHEMA, TABLE_NAME)
      JOIN information_schema.COLLATION_CHARACTER_SET_APPLICABILITY AS CCSA
        ON (T.TABLE_COLLATION = CCSA.COLLATION_NAME)
      WHERE TABLE_SCHEMA='#{config['database']}' AND C.DATA_TYPE IN ('enum', 'varchar', 'char', 'text', 'mediumtext', 'longtext') 
      ORDER BY TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME")
    r.each do |l|
      ActiveRecord::Base.connection.execute("alter table #{l[0]} modify #{l[1]} #{l[2]} character set utf8 collate utf8_unicode_ci") unless l[3] == 'utf8'
    end
  end
  
  desc "Migrate the database (options: VERSION=x, VERBOSE=false). Then convert to UTF8."
  task :migrate => :environment do
    Rake::Task["db:utf8"].invoke
  end
  
  namespace :schema do
    desc "Load a schema.rb file into the database and convert to UTF8."
    task :load => :environment do
      Rake::Task["db:utf8"].invoke
    end
  end
end

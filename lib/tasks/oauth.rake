namespace :db do  

  desc "Delete expired OAuth nonce strings from database" 
  task :nonce_clean => :environment do
    # Clean up nonces older than 5 minutes
    ActiveRecord::Base.connection.delete("delete from nonces where request_time < #{5.minutes.ago.to_i}")
  end

end

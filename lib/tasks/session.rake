namespace :db do  

  desc "Delete old sessions. Options: DAYS=30" 
  task :session_clean => :environment do
    age = (ENV["DAYS"].to_i if ENV["DAYS"].to_i > 0) || 30
    date = age.days.ago.utc.beginning_of_day.to_date
    ActiveRecord::SessionStore::Session.where("updated_at < '#{date}'").delete_all
  end

end
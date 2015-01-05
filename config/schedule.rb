# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# Cleanup the File-based cache store nightly at 1am
# Deletes expired items that haven't been accessed in a day.
# Deletes unexpired items that haven't been accessed in 30 days.
every :day, :at => '1:00 am' do
  rake "db:nonce_clean"
end

# Clean up old http_sessions nightly at 2am
every :day, :at => '2:00 am' do
  rake "db:session_clean DAYS=30"
end

#Process all grade updates
every 5.minutes do
  runner "Gradeupdate.process_all"
end

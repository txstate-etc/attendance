namespace :static do
  desc "Generate static pages and save them in /public"
  task :generate => :environment do
    require "rails/console/app"
    require "rails/console/helpers"
    extend Rails::ConsoleMethods

    urls_and_paths.each do |url, path|
      r = app.get(url)
      if 200 == r
        File.open(Rails.public_path + path, "w") do |f|
          f.write(app.response.body)
        end
      else
        $stderr.puts "Error generating static file #{path} #{r.inspect}"
      end
    end
  end
end

private
def urls_and_paths
  Dir.glob("#{Rails.root}/app/views/static/*.html.erb").map do |file|
    file = File.basename(file, '.html.erb')
    ["/static/#{file}", "/#{file}.html"]
  end
end
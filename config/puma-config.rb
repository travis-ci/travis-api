root = File.expand_path('../..', __FILE__)

rackup "#{root}/config.ru"

bind 'unix:///tmp/nginx.socket'

environment ENV['RACK_ENV'] || 'development'

threads 0, 16

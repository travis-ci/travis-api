root = File.expand_path('../..', __FILE__)

rackup "#{root}/config.ru"

bind "unix://#{ENV["tmp_dir"]}/nginx.socket"
environment ENV['RACK_ENV'] || 'development'

threads 0, 16

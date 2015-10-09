root = File.expand_path('../..', __FILE__)

rackup "#{root}/config.ru"

tmp_dir = ENV.fetch("tmp_dir", "/tmp")
bind "unix://#{tmp_dir}/nginx.socket"
environment ENV['RACK_ENV'] || 'development'

threads 0, 16

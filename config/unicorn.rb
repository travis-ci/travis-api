# http://michaelvanrooijen.com/articles/2011/06/01-more-concurrency-on-a-single-heroku-dyno-with-the-new-celadon-cedar-stack/

worker_processes Integer(ENV.fetch('WEB_CONCURRENCY')) # amount of unicorn workers to spin up
timeout 30 # restarts workers that hang for 30 seconds

tmp_dir = ENV.fetch("tmp_dir", "/tmp")
listen File.expand_path("nginx.socket", tmp_dir), backlog: 1024

require 'fileutils'
before_fork do |server, worker|
  # preload travis so we can have copy on write
  require 'travis/api/app'

  # kill old connections to logs db
  Travis::LogsModel.connection.disconnect!
  Travis::API::V3::Models::Log.connection.disconnect!

  # signal to nginx we're ready
  FileUtils.touch("#{tmp_dir}/app-initialized")
end

after_fork do |server, worker|
  require 'travis/api/app'

  # reestablish connections to logs db
  Travis::LogsModel.establish_connection(Travis.config.logs_database)
  Travis::API::V3::Models::Log.establish_connection(Travis.config.logs_database)
end

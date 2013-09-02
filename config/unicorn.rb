# http://michaelvanrooijen.com/articles/2011/06/01-more-concurrency-on-a-single-heroku-dyno-with-the-new-celadon-cedar-stack/

preload_app true
worker_processes 4 # amount of unicorn workers to spin up
timeout 30         # restarts workers that hang for 15 seconds

listen '/tmp/nginx.socket', backlog: 1024

require 'fileutils'
before_fork do |server,worker|
  FileUtils.touch('/tmp/app-initialized')
end

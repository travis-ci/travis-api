# http://michaelvanrooijen.com/articles/2011/06/01-more-concurrency-on-a-single-heroku-dyno-with-the-new-celadon-cedar-stack/

worker_processes 4 # amount of unicorn workers to spin up
timeout 30         # restarts workers that hang for 15 seconds

listen '/tmp/nginx.socket', backlog: 1024

require 'fileutils'
before_fork do |server,worker|
  FileUtils.touch('/tmp/app-initialized')
end

before_exec do |server|
  ENV['RUBY_HEAP_MIN_SLOTS']=800000
  ENV['RUBY_GC_MALLOC_LIMIT']=59000000
  ENV['RUBY_HEAP_SLOTS_INCREMENT']=10000
  ENV['RUBY_HEAP_SLOTS_GROWTH_FACTOR']=1
  ENV['RUBY_HEAP_FREE_MIN']=100000
end

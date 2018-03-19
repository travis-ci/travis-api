web: ./script/server-twemproxy
console: bundle exec je ./script/console
sidekiq: bundle exec je sidekiq -c 4 -r ./lib/travis/sidekiq.rb -q customerio
cron: bundle exec je ./bin/cron

web: bundle exec ./script/server
console: bundle exec ./script/console
sidekiq: bundle exec sidekiq -c 5 -r ./lib/travis/sidekiq.rb -q build_cancellations, -q build_restarts

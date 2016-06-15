# Travis Core Addons

The Addons are event handlers that accepts events such as "build finished" and forwards them to different services. The different services are:

- Campfire
- E-mail
- Flowdock
- GitHub Commit Statuses
- Hipchat
- IRC
- Pusher: Used to update our Web UI automatically.
- Sqwiggle
- States cache: Caches the state of each branch in Memcached for status images.
- Webhook
- Pushover

To add a new notification service, an event handler and a task is needed. The event handler is run by [`travis-hub`](https://github.com/travis-ci/travis-hub) and has access to the database. This should check whether the event should be forwarded at all, and pull out any necessary configuration values. It should then asynchronously run the corresponding Task. The Task is run by [`travis-tasks`](https://github.com/travis-ci/travis-tasks) via Sidekiq and should do the actual API calls needed. The event handler should finish very quickly, while the task is allowed to take longer. 

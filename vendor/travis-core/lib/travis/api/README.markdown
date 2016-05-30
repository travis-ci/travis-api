This directory contains serializers for events and models.

- `v0/event`: Payloads used by [`Travis::Event::Handler`](../event/handler.rb). These are the payloads that the [addons](../addons) will get.
- `v0/pusher`: Payloads used to send events to the web UI using Pusher.
- `v0/worker`: Payloads sent to [travis-worker](https://github.com/travis-ci/travis-worker).

- `v1/http`: Payloads for the v1 [API](https://github.com/travis-ci/travis-api).
- `v1/webhook`: Payloads for the webhook notifications.

- `v2/http`: Payloads for the v2 [API](https://github.com/travis-ci/travis-api).
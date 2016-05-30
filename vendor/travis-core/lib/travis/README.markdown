# Travis Core directory overview

This folder, `lib/travis` contains the main code for the Travis Core repository. It contains several sub-section/subdirectories:

- [`addons`](addons): Event handlers that take events such as "build finished" and sends out notifications to GitHub, Pusher, Campfire, etc.
- [`api`](api): Serializers for models and events used in our API and in some other places (for example to generate Pusher payloads).
- [`enqueue`](enqueue): Logic for enqueueing jobs.
- [`event`](event): Code for sending and subscribing to events. Used by the `addons` code to subscribe to changes in the models.
- [`github`](github): Services for communicating with the GitHub API.
- [`mailer`](mailer): ActionMailer mailers.
- [`model`](model): All of our ActiveRecord models.
- [`notification`](notification): Code for adding instrumentation.
- [`requests`](requests): Handles requests received from GitHub.
- [`secure_config.rb`](secure_config.rb): Logic for encrypting and decrypting build/job configs.
- [`services`](services): Most of the business logic behind our [API](https://github.com/travis-ci/travis-api).
- [`testing`](testing): Code used by our tests, such as model stubs and factories.

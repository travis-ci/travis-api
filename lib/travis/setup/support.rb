require 'travis/amqp'

module Travis::Setup
  module Support
    extend self

    def setup
      Travis::Async.enabled = true
      Travis::Amqp.setup(Travis.config.amqp) if Travis.config.amqp
    end
  end
end

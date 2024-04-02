require 'spec_helper'
require 'active_support/core_ext/hash/slice'

describe Travis::Config do
  # Run examples with a fresh ENV and restore original afterwards
  around do |example|
    old_env = ENV.to_h
    ENV.replace({})
    example.run
    ENV.replace(old_env)
  end

  let(:config) { Travis::Config.load(:files, :env, :heroku, :docker, :keychain) }
  let(:statement_timeout) { Travis::Config::Heroku::Database::VARIABLES[:statement_timeout] }

  describe 'endpoints' do
    it 'returns an object even without endpoints entry' do
      expect(config.endpoints.foo).to be_nil
    end

    it 'returns endpoints if it is set' do
      ENV['travis_config'] = YAML.dump('endpoints' => { 'ssh_key' => true })
      expect(config.endpoints.ssh_key).to be_truthy
    end

    it 'allows to set keys on enpoints when it is nil' do
      expect(config.endpoints.foo).to be_nil

      config.endpoints.foo = true

      expect(config.endpoints.foo).to be_truthy
    end
  end

  describe 'defaults' do
    it 'notifications defaults to []' do
      expect(config.notifications).to eq([])
    end

    it 'notifications.email defaults to {}' do
      expect(config.email).to eq({})
    end

    it 'queues defaults to []' do
      expect(config.queues).to eq([])
    end

    it 'ampq.host defaults to "localhost"' do
      expect(config.amqp.host).to eq('localhost')
    end

    it 'ampq.prefetch defaults to 1' do
      expect(config.amqp.prefetch).to eq(1)
    end

    it 'queue.limit.by_owner defaults to {}' do
      expect(config.queue.limit.by_owner).to eq({})
    end

    it 'queue.limit.default defaults to 5' do
      expect(config.queue.limit.default).to eq(5)
    end

    it 'queue.interval defaults to 3' do
      expect(config.queue.interval).to eq(3)
    end

    it 'queue.interval defaults to 3' do
      expect(config.queue.interval).to eq(3)
    end

    it 'logs.shards defaults to 1' do
      expect(config.logs.shards).to eq(1)
    end

    it 'database' do
      expect(config.database.to_h).to eq({
        :adapter => 'postgresql',
        :database => 'travis_test',
        :encoding => 'unicode',
        :min_messages => 'warning',
        :variables => { :statement_timeout => 10000 }
      })
    end
  end

  describe 'resource urls' do
    describe 'with a TRAVIS_DATABASE_URL set' do
      before { ENV['TRAVIS_DATABASE_URL'] = 'postgres://username:password@host:1234/database' }

      it { expect(config.database.username).to eq('username') }
      it { expect(config.database.password).to eq('password') }
      it { expect(config.database.host).to eq('host') }
      it { expect(config.database.port).to eq(1234) }
      it { expect(config.database.database).to eq('database') }
      it { expect(config.database.encoding).to eq('unicode') }
      it { expect(config.database.variables.application_name).not_to be_empty }
      it { expect(config.database.variables.statement_timeout).to eq statement_timeout }
    end

    describe 'with a DATABASE_URL set' do
      before { ENV['DATABASE_URL'] = 'postgres://username:password@host:1234/database' }

      it { expect(config.database.username).to eq('username') }
      it { expect(config.database.password).to eq('password') }
      it { expect(config.database.host).to eq('host') }
      it { expect(config.database.port).to eq(1234) }
      it { expect(config.database.database).to eq('database') }
      it { expect(config.database.encoding).to eq('unicode') }
      it { expect(config.database.variables.application_name).not_to be_empty }
      it { expect(config.database.variables.statement_timeout).to eq statement_timeout }
    end

    describe 'with a TRAVIS_RABBITMQ_URL set' do
      before { ENV['TRAVIS_RABBITMQ_URL'] = 'amqp://username:password@host:1234/vhost' }

      it { expect(config.amqp.username).to eq('username') }
      it { expect(config.amqp.password).to eq('password') }
      it { expect(config.amqp.host).to eq('host') }
      it { expect(config.amqp.port).to eq(1234) }
      it { expect(config.amqp.vhost).to eq('vhost') }
    end

    describe 'with a RABBITMQ_URL set' do
      before { ENV['RABBITMQ_URL'] = 'amqp://username:password@host:1234/vhost' }

      it { expect(config.amqp.username).to eq('username') }
      it { expect(config.amqp.password).to eq('password') }
      it { expect(config.amqp.host).to eq('host') }
      it { expect(config.amqp.port).to eq(1234) }
      it { expect(config.amqp.vhost).to eq('vhost') }
    end

    describe 'with a TRAVIS_REDIS_URL set' do
      before { ENV['TRAVIS_REDIS_URL'] = 'redis://username:password@host:1234' }

      it { expect(config.redis.url).to eq('redis://username:password@host:1234') }
    end

    describe 'with a REDIS_URL set' do
      before { ENV['REDIS_URL'] = 'redis://username:password@host:1234' }

      it { expect(config.redis.url).to eq('redis://username:password@host:1234') }
    end
  end
end

require 'spec_helper'
require 'active_support/core_ext/hash/slice'

describe Travis::Config do
  let(:config) { Travis::Config.load(:files, :env, :heroku, :docker) }

  describe 'endpoints' do
    it 'returns an object even without endpoints entry' do
      config.endpoints.foo.should be_nil
    end

    it 'returns endpoints if it is set' do
      ENV['travis_config'] = YAML.dump('endpoints' => { 'ssh_key' => true })
      config.endpoints.ssh_key.should be_true
    end

    it 'allows to set keys on enpoints when it is nil' do
      config.endpoints.foo.should be_nil

      config.endpoints.foo = true

      config.endpoints.foo.should be_true
    end
  end

  describe 'defaults' do
    it 'notifications defaults to []' do
      config.notifications.should == []
    end

    it 'notifications.email defaults to {}' do
      config.email.should == {}
    end

    it 'queues defaults to []' do
      config.queues.should == []
    end

    it 'ampq.host defaults to "localhost"' do
      config.amqp.host.should == 'localhost'
    end

    it 'ampq.prefetch defaults to 1' do
      config.amqp.prefetch.should == 1
    end

    it 'queue.limit.by_owner defaults to {}' do
      config.queue.limit.by_owner.should == {}
    end

    it 'queue.limit.default defaults to 5' do
      config.queue.limit.default.should == 5
    end

    it 'queue.interval defaults to 3' do
      config.queue.interval.should == 3
    end

    it 'queue.interval defaults to 3' do
      config.queue.interval.should == 3
    end

    it 'logs.shards defaults to 1' do
      config.logs.shards.should == 1
    end

    it 'database' do
      config.database.should == {
        :adapter => 'postgresql',
        :database => 'travis_test',
        :encoding => 'unicode',
        :min_messages => 'warning',
        :variables => { :statement_timeout => 10000 }
      }
    end
  end

  describe 'resource urls' do
    describe 'with a TRAVIS_DATABASE_URL set' do
      before { ENV['TRAVIS_DATABASE_URL'] = 'postgres://username:password@host:1234/database' }
      after  { ENV.delete('TRAVIS_DATABASE_URL') }

      it { config.database.username.should == 'username' }
      it { config.database.password.should == 'password' }
      it { config.database.host.should == 'host' }
      it { config.database.port.should == 1234 }
      it { config.database.database.should == 'database' }
      it { config.database.encoding.should == 'unicode' }
    end

    describe 'with a DATABASE_URL set' do
      before { ENV['DATABASE_URL'] = 'postgres://username:password@host:1234/database' }
      after  { ENV.delete('DATABASE_URL') }

      it { config.database.username.should == 'username' }
      it { config.database.password.should == 'password' }
      it { config.database.host.should == 'host' }
      it { config.database.port.should == 1234 }
      it { config.database.database.should == 'database' }
      it { config.database.encoding.should == 'unicode' }
    end

    describe 'with a TRAVIS_LOGS_DATABASE_URL set' do
      before { ENV['TRAVIS_LOGS_DATABASE_URL'] = 'postgres://username:password@host:1234/database' }
      after  { ENV.delete('TRAVIS_LOGS_DATABASE_URL') }

      it { config.logs_database.username.should == 'username' }
      it { config.logs_database.password.should == 'password' }
      it { config.logs_database.host.should == 'host' }
      it { config.logs_database.port.should == 1234 }
      it { config.logs_database.database.should == 'database' }
      it { config.logs_database.encoding.should == 'unicode' }
    end

    describe 'with a LOGS_DATABASE_URL set' do
      before { ENV['LOGS_DATABASE_URL'] = 'postgres://username:password@host:1234/database' }
      after  { ENV.delete('LOGS_DATABASE_URL') }

      it { config.logs_database.username.should == 'username' }
      it { config.logs_database.password.should == 'password' }
      it { config.logs_database.host.should == 'host' }
      it { config.logs_database.port.should == 1234 }
      it { config.logs_database.database.should == 'database' }
      it { config.logs_database.encoding.should == 'unicode' }
    end

    describe 'with a TRAVIS_RABBITMQ_URL set' do
      before { ENV['TRAVIS_RABBITMQ_URL'] = 'amqp://username:password@host:1234/vhost' }
      after  { ENV.delete('TRAVIS_RABBITMQ_URL') }

      it { config.amqp.username.should == 'username' }
      it { config.amqp.password.should == 'password' }
      it { config.amqp.host.should == 'host' }
      it { config.amqp.port.should == 1234 }
      it { config.amqp.vhost.should == 'vhost' }
    end

    describe 'with a RABBITMQ_URL set' do
      before { ENV['RABBITMQ_URL'] = 'amqp://username:password@host:1234/vhost' }
      after  { ENV.delete('RABBITMQ_URL') }

      it { config.amqp.username.should == 'username' }
      it { config.amqp.password.should == 'password' }
      it { config.amqp.host.should == 'host' }
      it { config.amqp.port.should == 1234 }
      it { config.amqp.vhost.should == 'vhost' }
    end

    describe 'with a TRAVIS_REDIS_URL set' do
      before { ENV['TRAVIS_REDIS_URL'] = 'redis://username:password@host:1234' }
      after  { ENV.delete('TRAVIS_REDIS_URL') }

      it { config.redis.url.should == 'redis://username:password@host:1234' }
    end

    describe 'with a REDIS_URL set' do
      before { ENV['REDIS_URL'] = 'redis://username:password@host:1234' }
      after  { ENV.delete('REDIS_URL') }

      it { config.redis.url.should == 'redis://username:password@host:1234' }
    end
  end
end

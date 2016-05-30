require 'dalli'
require 'connection_pool'
require 'active_support/core_ext/module/delegation'
require 'travis/api'

module Travis
  class StatesCache
    class CacheError < StandardError; end

    include Travis::Api::Formats

    attr_reader :adapter

    delegate :fetch, :to => :adapter

    def initialize(options = {})
      @adapter = options[:adapter] || MemcachedAdapter.new
    end

    def write(id, branch, data)
      if data.respond_to?(:id)
        data = {
          'id' => data.id,
          'state' => data.state.to_s
        }
      end

      adapter.write(id, branch, data)
    end

    def fetch_state(id, branch)
      data = fetch(id, branch)
      data['state'].to_sym if data && data['state']
    end

    class TestAdapter
      attr_reader :calls
      def initialize
        @calls = []
      end

      def fetch(id, branch)
        calls << [:fetch, id, branch]
      end

      def write(id, branch, data)
        calls << [:write, id, branch, data]
      end

      def clear
        calls.clear
      end
    end

    class MemcachedAdapter
      attr_reader :pool
      attr_accessor :jitter
      attr_accessor :ttl

      def initialize(options = {})
        @pool = ConnectionPool.new(:size => 10, :timeout => 3) do
          if options[:client]
            options[:client]
          else
            new_dalli_connection
          end
        end
        @jitter = 0.5
        @ttl = 7.days
      end

      def fetch(id, branch = nil)
        data = get(key(id, branch))
        data ? JSON.parse(data) : nil
      end

      def write(id, branch, data)
        build_id = data['id']
        data     = data.to_json

        Travis.logger.info("[states-cache] Writing states cache for repo_id=#{id} branch=#{branch} build_id=#{build_id}")
        set(key(id), data) if update?(id, nil, build_id)
        set(key(id, branch), data) if update?(id, branch, build_id)
      end

      def update?(id, branch, build_id)
        current_data = fetch(id, branch)
        return true unless current_data

        current_id = current_data['id'].to_i
        new_id     = build_id.to_i

        update = new_id >= current_id
        message = "[states-cache] Checking if cache is stale for repo_id=#{id} branch=#{branch}. "
        if update
          message << "The cache is going to get an update, "
        else
          message << "The cache is fresh, "
        end
        message << "last cached build id=#{current_id}, we're checking build with id=#{new_id}"
        Travis.logger.info(message)

        return update
      end

      def key(id, branch = nil)
        key = "state:#{id}"
        if branch
          key << "-#{branch}"
        end
        key
      end

      private

      def new_dalli_connection
        Dalli::Client.new(Travis.config.states_cache.memcached_servers, Travis.config.states_cache.memcached_options)
      end

      def get(key)
        retry_ringerror do
          pool.with { |client| client.get(key) }
        end
      rescue Dalli::RingError => e
        Metriks.meter("memcached.connect-errors").mark
        raise CacheError, "Couldn't connect to a memcached server: #{e.message}"
      end

      def set(key, data)
        retry_ringerror do
          pool.with { |client| client.set(key, data) }
          Travis.logger.info("[states-cache] Setting cache for key=#{key} data=#{data}")
        end
      rescue Dalli::RingError => e
        Metriks.meter("memcached.connect-errors").mark
        Travis.logger.info("[states-cache] Writing cache key failed key=#{key} data=#{data}")
        raise CacheError, "Couldn't connect to a memcached server: #{e.message}"
      end

      def retry_ringerror
        retries = 0
        begin
          yield
        rescue Dalli::RingError
          retries += 1
          if retries <= 3
            # Sleep for up to 1/2 * (2^retries - 1) seconds
            # For retries <= 3, this means up to 3.5 seconds
            sleep(jitter * (rand(2 ** retries - 1) + 1))
            retry
          else
            raise
          end
        end
      end
    end
  end
end

module Travis
  class Config
    class Database < Struct.new(:options)
      include Helpers

      VARIABLES = { application_name: ENV['DYNO'] || $0, statement_timeout: 10_000 }
      DEFAULTS  = { adapter: 'postgresql', encoding: 'unicode', variables: VARIABLES }

      def config
        config = compact(Url.parse(url).to_h)
        config = deep_merge(DEFAULTS, config) unless config.empty?
        config[:pool] = pool.to_i if pool
        config
      end

      private

        def url
          env('DATABASE_URL').compact.first
        end

        def pool
          env('DATABASE_POOL_SIZE', 'DB_POOL').compact.first
        end

        def env(*keys)
          ENV.values_at(*keys.map { |key| prefix(key) }.flatten)
        end

        def prefix(key)
          key = [options[:prefix], key].compact.join('_').upcase
          ["TRAVIS_#{key}", key]
        end

        def options
          super || {}
        end
    end
  end
end

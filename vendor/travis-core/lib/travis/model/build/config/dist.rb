class Build
  class Config
    class Dist
      DIST_LANGUAGE_MAP = {
        'objective-c' => 'osx'
      }.freeze
      DIST_OS_MAP = {
        'osx' => 'osx'
      }.freeze
      DIST_SERVICES_MAP = {
        'docker' => 'trusty'
      }.freeze
      DEFAULT_DIST = 'precise'

      attr_reader :config, :options

      def initialize(config, options)
        @config = config
        @options = options
      end

      def run
        return config unless config_hashy?
        return config if config.key?(:dist) || config.key?('dist')

        config.dup.tap do |c|
          c.merge!(dist: dist_for_config)

          matrix = c.fetch(:matrix, {})
          return c unless config_hashy?(matrix)

          included = matrix.fetch(:include, []) || []

          included.each do |inc|
            next unless config_hashy?(inc)
            next if inc.key?(:dist) || inc.key?('dist')
            inc.merge!(dist: dist_for_config(inc))
          end
        end
      end

      private

      def config_hashy?(h = config)
        %w(key? dup merge! fetch).all? { |m| h.respond_to?(m) }
      end

      def dist_for_config(h = config)
        return DIST_LANGUAGE_MAP[h[:language]] if
          DIST_LANGUAGE_MAP.key?(h[:language])
        (Array(h[:services]) || []).each do |service|
          return DIST_SERVICES_MAP[service] if DIST_SERVICES_MAP.key?(service)
        end
        return DEFAULT_DIST if options[:multi_os]
        DIST_OS_MAP.fetch(Array(h[:os]).first, DEFAULT_DIST)
      end
    end
  end
end

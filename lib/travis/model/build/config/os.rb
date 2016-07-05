class Build
  class Config
    class OS
      OS_LANGUAGE_MAP = {
        'objective-c' => 'osx',
      }
      DEFAULT_OS = 'linux'

      attr_reader :config

      def initialize(config, _)
        @config = config
      end

      def run
        return config if config.key?(:os) || config.key?('os')
        config.merge(os: os_for_language)
      end

      private

      def os_for_language
        OS_LANGUAGE_MAP.fetch(config[:language], DEFAULT_OS)
      end
    end
  end
end

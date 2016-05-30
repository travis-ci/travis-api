class Build
  class Config
    class Group
      DEFAULT_GROUP = 'stable'

      attr_reader :config

      def initialize(config, *)
        @config = config
      end

      def run
        return config if config.key?(:group) || config.key?('group')
        config.merge(group: DEFAULT_GROUP)
      end
    end
  end
end

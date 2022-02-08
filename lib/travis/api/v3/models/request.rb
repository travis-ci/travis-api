module Travis::API::V3
  module Models
    class RequestConfigs < Struct.new(:data)
      def raw_configs
        Array(data[:raw_configs]).map do |attrs|
          raw_config = RequestRawConfig.new(config: attrs[:config])
          RequestRawConfiguration.new(source: attrs[:source], merge_mode: attrs[:mode], raw_config: raw_config)
        end
      end

      def request_config
        RequestConfig.new(config: data[:config])
      end

      def job_configs
        Array(data[:matrix]).map { |attrs| JobConfig.new(config: attrs) }
      end

      def messages
        Array(data[:messages]).map { |attrs| Message.new(attrs) }
      end

      def full_messages
        data[:full_messages]
      end
    end

    class RequestConfig < Model
    end

    class RequestYamlConfig < Model
    end

    class RequestRawConfig < Model
    end

    class RequestRawConfiguration < Model
      belongs_to :request
      belongs_to :raw_config, foreign_key: :request_raw_config_id, class_name: 'RequestRawConfig'
    end

    class Request < Model
      def self.columns
        super.reject { |c| c.name == 'payload' }
      end

      belongs_to :commit
      belongs_to :pull_request
      belongs_to :repository
      belongs_to :owner, polymorphic: true
      belongs_to :config, foreign_key: :config_id, class_name: 'RequestConfig'
      belongs_to :yaml_config, foreign_key: :yaml_config_id, class_name: 'RequestYamlConfig'
      has_many   :raw_configurations, -> { order 'request_raw_configurations.id' }, class_name: 'RequestRawConfiguration'
      has_many   :raw_configs, through: :raw_configurations, class_name: 'RequestRawConfig'
      has_many   :builds
      serialize  :config
      serialize  :payload
      has_many   :messages, -> { unscope(where: :subject_type).where(subject_type: 'Request') }, as: :subject

      def branch_name
        commit.branch_name if commit
      end

      def config=(config)
        raise unless ENV['RACK_ENV'] == 'test'
        config = RequestConfig.new(repository_id: repository_id, key: 'key', config: config)
        super(config)
      end

      def config
        record = super
        config = record&.config_json if record.respond_to?(:config_json)
        config ||= record&.config
        config ||= read_attribute(:config) if has_attribute?(:config)
        config ||= {}
        config.deep_symbolize_keys! if config.respond_to?(:deep_symbolize_keys!)
        config
      end

      def yaml_config
        super
      end

      def payload
        raise "[deprecated] Reading request.payload}"
      end
    end
  end
end

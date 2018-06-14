module Travis::API::V3
  class Models::RequestConfig < Model
  end

  class Models::RequestYamlConfig < Model
  end

  class Models::Request < Model
    def self.columns
      super.reject { |c| c.name == 'payload' }
    end

    belongs_to :commit
    belongs_to :pull_request
    belongs_to :repository
    belongs_to :owner, polymorphic: true
    belongs_to :config, foreign_key: :config_id, class_name: Models::RequestConfig
    belongs_to :yaml_config, foreign_key: :yaml_config_id, class_name: Models::RequestYamlConfig
    has_many   :builds
    serialize  :config
    serialize  :payload
    has_many   :messages, as: :subject

    def branch_name
      commit.branch_name if commit
    end

    def config=(config)
      raise unless ENV['RACK_ENV'] == 'test'
      config = Models::RequestConfig.new(repository_id: repository_id, key: 'key', config: config)
      super(config)
    end

    def config
      config = super&.config || has_attribute?(:config) && read_attribute(:config) || {}
      config.deep_symbolize_keys! if config.respond_to?(:deep_symbolize_keys!)
      config
    end

    def yaml_config
      super&.yaml
    end

    def payload
      raise "[deprecated] Reading request.payload}"
    end
  end
end

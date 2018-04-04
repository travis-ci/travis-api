module Travis::API::V3
  class Models::RequestConfig < Model
    serialize :config
  end

  class Models::Request < Model
    belongs_to :commit
    belongs_to :pull_request
    belongs_to :repository
    belongs_to :owner, polymorphic: true
    belongs_to :config, foreign_key: :config_id, class_name: Models::RequestConfig
    has_many   :builds
    serialize  :config
    serialize  :payload
    has_many   :messages, as: :subject

    def branch_name
      commit.branch if commit
    end

    def config=(config)
      raise unless ENV['RACK_ENV'] == 'test'
      config = Models::RequestConfig.new(repository_id: repository_id, key: 'key', config: config)
      super(config)
    end

    def config
      super&.config || read_attribute(:config) || {}
    end

    def payload
      raise "[deprecated] Reading request.payload}"
    end
  end
end

require 'travis/config/defaults'

module Travis::API::V3
  class Models::JobConfig < Model
  end

  class Models::Job < Model

    self.inheritance_column = :_type_disabled

    belongs_to :repository
    belongs_to :commit
    belongs_to :build, autosave: true, foreign_key: 'source_id'
    belongs_to :stage
    belongs_to :owner, polymorphic: true
    belongs_to :config, foreign_key: :config_id, class_name: Models::JobConfig
    serialize :config
    serialize :debug_options

    def log
      @log ||= Travis::RemoteLog.find_by_job_id(id)
    end

    def state
      super || 'created'
    end

    def public?
      !private?
    end

    def config=(config)
      raise unless ENV['RACK_ENV'] == 'test'
      config = Models::JobConfig.new(repository_id: repository_id, key: 'key', config: config)
      super(config)
    end

    def config
      config = super&.config || has_attribute?(:config) && read_attribute(:config) || {}
      config.deep_symbolize_keys! if config.respond_to?(:deep_symbolize_keys!)
      config
    end
  end
end

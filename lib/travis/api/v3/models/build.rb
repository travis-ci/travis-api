module Travis::API::V3
  class Models::BuildConfig < Model
  end

  class Models::Build < Model

    HIGH_PRIORITY = 5

    self.table_name = 'builds'
    
    belongs_to :commit
    belongs_to :tag
    belongs_to :pull_request
    belongs_to :request
    belongs_to :repository, autosave: true
    belongs_to :owner, polymorphic: true
    belongs_to :sender, polymorphic: true
    belongs_to :config, foreign_key: :config_id, class_name: 'Models::BuildConfig'.freeze

    has_many :stages

    has_many :jobs,
      -> { order('id') },
      foreign_key: :source_id,
      dependent:   :destroy,
      class_name:  'Travis::API::V3::Models::Job'.freeze

    has_many :active_jobs,
      -> { where("jobs.state IN ('received', 'queued', 'started')".freeze).order('id') },
      foreign_key: :source_id,
      class_name:  'Travis::API::V3::Models::Job'.freeze

    has_one :branch,
      foreign_key: :last_build_id,
      primary_key: [:repository_id, :branch],
      class_name:  'Travis::API::V3::Models::Branch'.freeze

    scope :running_builds, -> { where.not(state: ['passed', 'failed', 'errored', 'cancelled']) }

    def created_by
      return unless sender
      sender.becomes(created_by_class)
    end

    def created_by_class
      return unless sender
      case sender_type
      when 'User' then V3::Models::User
      when 'Organization' then V3::Models::Organization
      end
    end

    def state
      super || 'created'
    end

    def branch_name
      read_attribute(:branch)
    end

    def job_ids
      return super unless cached = cached_matrix_ids

      # AR 3.2 does not handle pg arrays and the plugins supporting them
      # do not work well with jdbc drivers
      # TODO: remove this once we're on >= 4.0
      cached = cached.gsub(/^{|}$/, '').split(',').map(&:to_i) unless cached.is_a? Array
      cached
    end

    def config=(config)
      raise unless ENV['RACK_ENV'] == 'test'
      config = Models::BuildConfig.new(repository_id: repository_id, key: 'key', config: config)
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

    def branch_name=(value)
      write_attribute(:branch, value)
    end

    def clear_debug_options!
      jobs.each { |j| j.update_attribute(:debug_options, nil) }
    end

    def log_complete
      jobs.all?(&:log_complete)
    end

    def high_priority?
      jobs.where(priority: HIGH_PRIORITY).present?
    end
  end
end

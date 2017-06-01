module Travis::API::V3
  class Models::Build < Model
    belongs_to :commit
    belongs_to :pull_request
    belongs_to :request
    belongs_to :repository, autosave: true
    belongs_to :owner, polymorphic: true
    belongs_to :sender, polymorphic: true

    has_many :stages

    has_many :jobs,
      foreign_key: :source_id,
      order:       :id,
      dependent:   :destroy,
      class_name:  'Travis::API::V3::Models::Job'.freeze

    has_many :active_jobs,
      foreign_key: :source_id,
      order:       :id,
      conditions:  "jobs.state IN ('received', 'queued', 'started')".freeze,
      class_name:  'Travis::API::V3::Models::Job'.freeze

    has_one :branch,
      foreign_key: [:repository_id, :name],
      primary_key: [:repository_id, :branch],
      class_name:  'Travis::API::V3::Models::Branch'.freeze

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

    def branch_name=(value)
      write_attribute(:branch, value)
    end

    def clear_debug_options!
      jobs.each { |j| j.update_attribute(:debug_options, nil) }
    end
  end
end

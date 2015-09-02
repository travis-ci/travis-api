module Travis::API::V3
  class Models::Build < Model
    belongs_to :repository
    belongs_to :commit
    belongs_to :request
    belongs_to :repository, autosave: true
    belongs_to :owner, polymorphic: true

    has_many :jobs,
      as:        :source,
      order:     :id,
      dependent: :destroy

    has_one :branch,
      foreign_key: [:repository_id, :name],
      primary_key: [:repository_id, :branch],
      class_name:  'Travis::API::V3::Models::Branch'.freeze

    def branch_name
      read_attribute(:branch)
    end

    def branch_name=(value)
      write_attribute(:branch, value)
    end
  end
end

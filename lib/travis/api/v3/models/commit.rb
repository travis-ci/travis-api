module Travis::API::V3
  class Models::Commit < Model
    belongs_to :repository
    has_one    :request
    belongs_to :tag
    has_many   :builds

    has_one :branch, -> { joins('inner join commits on branches.repository_id = commits.repository_id and commits.branch = branches.name') },
      class_name:  'Travis::API::V3::Models::Branch'.freeze

    def branch_name
      read_attribute(:branch)
    end

    def branch_name=(value)
      write_attribute(:branch, value)
    end
  end
end

module Travis::API::V3
  class Models::Commit < Model
    belongs_to :repository
    has_one    :request
    has_many   :builds

    # has_one :branch,
    #   foreign_key: [:repository_id, :name],
    #   primary_key: [:repository_id, :branch],
    #   class_name:  'Travis::API::V3::Models::Branch'.freeze

    def branch_name
      read_attribute(:branch)
    end

    def branch_name=(value)
      write_attribute(:branch, value)
    end

    def branch
      Travis::API::V3::Models::Branch.where(repository_id: repository_id, name: branch_name).first
    end
  end
end

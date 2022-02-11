module Travis::API::V3
  class Models::Commit < Model
    belongs_to :repository
    has_one    :request
    belongs_to :tag
    has_many   :builds

    def branch
      Travis::API::V3::Models::Branch
        .all.joins("inner join commits on #{repository_id} = branches.repository_id and '#{attributes['branch']}' = branches.name").first
    end

    def branch_name
      read_attribute(:branch)
    end

    def branch_name=(value)
      write_attribute(:branch, value)
    end
  end
end

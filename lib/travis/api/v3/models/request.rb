module Travis::API::V3
  class Models::Request < Model
    belongs_to :commit
    belongs_to :repository
    belongs_to :owner, polymorphic: true
    has_many   :builds
    serialize  :config
    serialize  :payload

    # has_one :branch_name,
    #   primary_key: [:id,  :branch_name]

    def branch_name
      read_attribute(:branch_name)
    end
  end
end

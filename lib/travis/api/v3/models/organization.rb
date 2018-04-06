module Travis::API::V3
  class Models::Organization < Model
    has_many :memberships
    has_many :users, through: :memberships

    has_one :installation, as: :owner
  
    def repositories
      Models::Repository.where(owner_type: 'Organization', owner_id: id)
    end

    alias members users
  end
end

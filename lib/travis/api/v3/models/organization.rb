module Travis::API::V3
  class Models::Organization < Model
    has_many :memberships
    has_many :users, through: :memberships

    def repositories
      Models::Repository.where(owner_type: 'Organization', owner_id: id)
    end

    def installation
      return @installation if defined? @installation
      @installation = Models::Installation.find_by(owner_type: 'Organization', owner_id: id, removed_on: nil)
    end

    def education
      Travis::Features.owner_active?(:education, self)
    end

    alias members users
  end
end

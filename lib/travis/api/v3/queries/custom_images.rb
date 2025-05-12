module Travis::API::V3
  class Queries::CustomImages < Query
    def for_owner(owner)
      Models::CustomImage.where(owner_id: owner.id, owner_type: owner_type(owner))
    end

    private

    def owner_type(owner)
      owner.vcs_type =~ /User/ ? 'User' : 'Organization'
    end
  end
end

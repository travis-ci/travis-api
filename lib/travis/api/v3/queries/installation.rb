module Travis::API::V3
  class Queries::Installation < Query
    def for_owner(owner)
      Travis::API::V3::Models::Installation.where(owner_type: owner.class.name.demodulize, owner_id: owner.id)
    end
  end
end
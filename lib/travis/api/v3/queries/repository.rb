module Travis::API::V3
  class Queries::Repository < Query
    params :id, :slug

    def find
      return by_slug if slug
      return Models::Repository.find_by_id(id) if id
      raise WrongParams, 'missing repository.id'.freeze
    end

    private

    def by_slug
      owner_name, name = slug.split('/')
      Models::Repository.where(owner_name: owner_name, name: name).first
    end
  end
end

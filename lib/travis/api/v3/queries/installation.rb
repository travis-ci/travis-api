module Travis::API::V3
  class Queries::Installation < Query
  	params :id

  	def find
      return Models::Installation.where(github_id: id) if id
      raise WrongParams, 'missing github_id'.freeze
    end
  end
end
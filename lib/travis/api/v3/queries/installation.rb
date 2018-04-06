module Travis::API::V3
  class Queries::Installation < Query

  	def find
      Models::Installation.find_by_github_id(id)
    end
  end
end
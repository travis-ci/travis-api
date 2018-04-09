module Travis::API::V3
  class Queries::Installation < Query
    params :github_id

    def find
      Models::Installation.find_by_github_id(github_id) if github_id
    end
  end
end

module Travis::API::V3
  class Queries::Cron < Query
    params :id

    sortable_by :id

    def find
      return Models::Cron.find_by_id(id) if id
      raise WrongParams, 'missing cron.id'.freeze
    end

    def find_for_branch(branch)
      branch.cron
    end
  end
end

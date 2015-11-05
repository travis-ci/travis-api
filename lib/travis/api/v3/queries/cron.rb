module Travis::API::V3
  class Queries::Cron < Query
    params :id

    sortable_by :id

    def find
      return Models::Repository.find_by_id(id) if id
      raise WrongParams, 'missing job.id'.freeze
    end
  end
end

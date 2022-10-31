module Travis::API::V3
  class Queries::BuildBackups < Query
    params :repository_id

    def all
      return Models::BuildBackup.where(repository_id: repository_id) if repository_id
      raise WrongParams, 'missing build_backups.repository_id'.freeze
    end
  end
end

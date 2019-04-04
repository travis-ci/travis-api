require 'travis/api/v3/models/repository_migration'

module Travis::API::V3
  class Services::Repository::Migrate < Service
    def run!
      repository = check_login_and_find(:repository)
      check_access(repository)
      return repo_migrated if migrated?(repository)

      current_user = access_control.user
      owner = repository.owner

      Models::RepositoryMigration.new(repository).migrate!

      Travis.logger.info(
        "Repo Migration Request: Repo ID: #{repository.id}, User: #{current_user.id}"
      )

      result(repository, status: 202)
    rescue Models::RepositoryMigration::MigrationDisabledError
      message = "Migrating repositories is disabled for #{owner.login}. Please contact Travis CI support for more information."
      raise Error.new(message, status: 403)
    rescue Models::RepositoryMigration::MigrationRequestFailed
      message = 'There was a problem with migrating a repository. Please contact Travis CI support for more information'
      raise Error.new(message, status: 500)
    end

    private def check_access(repository)
      access_control.permissions(repository).migrate!
    end
  end
end

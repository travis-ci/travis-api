require 'travis/api/v3/services/repository/deactivate'

module Travis::API::V3
  class Services::Repository::Activate < Service
    def run!
      repository = check_login_and_find(:repository)
      check_access(repository)
      check_repo_key(repository)
      return repo_migrated if migrated?(repository)

      admin = Travis.config.legacy_roles || access_control.class.name == 'Travis::API::V3::AccessControl::Internal' ?
              access_control.admin_for(repository) :
              access_control.user

      raise NotFound unless admin&.id

      remote_vcs_repository.set_hook(
        repository_id: repository.id,
        user_id: admin.id
      )

      repository.update(active: true)

      if repository.perforce?
        remote_vcs_repository.create_perforce_group(
          repository_id: repository.id,
          user_id: admin.id
        )

        remote_vcs_repository.set_perforce_ticket(
          repository_id: repository.id,
          user_id: admin.id
        )
      elsif repository.private? || access_control.enterprise?
        remote_vcs_repository.upload_key(
          repository_id: repository.id,
          user_id: admin.id,
          read_only: !repository.subversion? && !Travis::Features.owner_active?(:read_write_github_keys, repository.owner)
        )
      end

      query.sync(access_control.user || access_control.admin_for(repository))
      save_audit(repository)
      result repository
    end

    def check_access(repository)
      access_control.permissions(repository).activate!
    end

    def check_repo_key(repository)
      if repository.subversion? && repository.key.nil?
        key = Travis::API::V3::Models::SslKey.new(repository: repository)
        key.generate_keys!
        key.save!

        return
      end

      raise RepoSshKeyMissing if repository.key.nil?
    end

    def save_audit(repository)
      app_id = Travis::Api::App::AccessToken.find_by_token(access_control.token)&.app_id
      change_source = (app_id.nil? || app_id == 2) ? 'admin-v2' : 'travis-api'
      Travis::API::V3::Models::Audit.create!(owner: access_control.user, change_source: change_source, source: repository, source_changes: { active: [false, true] })
    end
  end
end

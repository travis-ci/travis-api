module Travis::API::V3
  class Services::Repository::Deactivate < Service
    def run!(activate = false)
      repository = check_login_and_find(:repository)
      check_access(repository)

      return repo_migrated if migrated?(repository)

      if Travis.config.legacy_roles || access_control.class.name == 'Travis::API::V3::AccessControl::Internal'
        admin = access_control.admin_for(repository)
      else
        admin = access_control.user
      end

      raise InsufficientAccess unless admin&.id

      remote_vcs_repository.set_hook(
        repository_id: repository.id,
        user_id: admin.id,
        activate: activate
      )

      if repository.perforce?
        begin
          remote_vcs_repository.delete_perforce_group(
            repository_id: repository.id,
            user_id: admin.id
          )
        rescue Travis::RemoteVCS::ResponseError
          # Do nothing, the group is already removed
        end

        if repository.key.present?
          repository.key.generate_keys!
          repository.key.save!
        end
      elsif repository.key.present?
        keys = remote_vcs_repository.keys(
          repository_id: repository.id,
          user_id: admin.id
        )
        fingerprint = PrivateKey.new(repository.key.private_key).fingerprint.gsub(':', '')
        matched_key = keys.detect { |key| key['fingerprint'] == fingerprint }
        remote_vcs_repository.delete_key(
          repository_id: repository.id,
          user_id: admin.id,
          id: matched_key['id']
        ) if matched_key.present?
        repository.key.destroy if repository.subversion?
      end

      repository.update(active: activate)
      save_audit(repository)
      result repository
    end

    def check_access(repository)
      access_control.permissions(repository).deactivate!
    end

    def save_audit(repository)
      app_id = Travis::Api::App::AccessToken.find_by_token(access_control.token)&.app_id
      change_source = (app_id.nil? || app_id == 2) ? 'admin-v2' : 'travis-api'
      Travis::API::V3::Models::Audit.create!(owner: access_control.user, change_source: change_source, source: repository, source_changes: { active: [true, false] })
    end
  end
end

module Travis::API::V3
  class Queries::AccountEnvVar < Query

    def find(params)
      Models::AccountEnvVar.where(owner_type: params['owner_type'], owner_id: params['owner_id'])
    end

    def create(params, current_user)
      raise UnprocessableEntity, "'#{params['name']}' environment variable already exists." unless Models::AccountEnvVar.where(name: params['name'], owner_id: params['owner_id'], owner_type: params['owner_type']).count.zero?

      env_var = Travis::API::V3::Models::AccountEnvVar.new.save_account_env_var!(
        params['owner_type'],
        params['owner_id'],
        params['name'],
        params['value'],
        params['public']
      )

      Travis::API::V3::Models::Audit.create!(
        owner: current_user,
        change_source: 'travis-api',
        source: env_var,
        source_changes: {
          action: 'create',
          fingerprint: env_var.id
        }
      )
      env_var
    end

    def delete(params, current_user)
      env_var = Travis::API::V3::Models::AccountEnvVar.find(params['id'])
      Travis::API::V3::Models::Audit.create!(
        owner: current_user,
        change_source: 'travis-api',
        source: env_var,
        source_changes: {
          action: 'delete',
          name: env_var.name,
          owner_type: env_var.owner_type,
          owner_id: env_var.owner_id
        }
      )

      env_var.destroy
    end
  end
end

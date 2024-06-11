module Travis::API::V3
  class Queries::CustomKey < Query
    def create(params, current_user)
      raise UnprocessableEntity, 'Key with this identifier already exists.' unless Travis::API::V3::Models::CustomKey.where(name: params['name'], owner_id: params['owner_id'], owner_type: params['owner_type']).count.zero?

      if params['owner_type'] == 'User'
        org_ids = User.find(params['owner_id']).organizations.map(&:id)

        raise UnprocessableEntity, 'Key with this identifier already exists in one of your organizations.' unless Travis::API::V3::Models::CustomKey.where(name: params['name'], owner_id: org_ids, owner_type: 'Organization').count.zero?
      elsif params['owner_type'] == 'Organization'
        user_ids = Membership.where(organization_id: params['owner_id']).map(&:user_id)

        raise UnprocessableEntity, 'Key with this identifier already exists for your user.' unless Travis::API::V3::Models::CustomKey.where(name: params['name'], owner_id: user_ids, owner_type: 'User').count.zero?
      end

      key = Travis::API::V3::Models::CustomKey.new.save_key!(
        params['owner_type'],
        params['owner_id'],
        params['name'],
        params['description'],
        params['private_key'],
        params['added_by'],
        params['public_key']
      )
      handle_errors(key) unless key.valid?

      Travis::API::V3::Models::Audit.create!(
        owner: current_user,
        change_source: 'travis-api',
        source: key,
        source_changes: {
          action: 'create',
          fingerprint: key.fingerprint
        }
      )

      key
    end

    def delete(params, current_user)
      key = Travis::API::V3::Models::CustomKey.find(params['id'])
      Travis::API::V3::Models::Audit.create!(
        owner: current_user,
        change_source: 'travis-api',
        source: key,
        source_changes: {
          action: 'delete',
          name: key.name,
          owner_type: key.owner_type,
          owner_id: key.owner_id,
          fingerprint: key.fingerprint
        }
      )

      key.destroy
    end

    private

    def handle_errors(key)
      private_key = key.errors[:private_key]
      raise UnprocessableEntity, 'This key is not a private key.' if private_key.include?('invalid_pem')
      raise WrongParams         if private_key.include?('missing_attr')
    end
  end
end

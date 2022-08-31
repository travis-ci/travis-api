module Travis::API::V3
  class Queries::CustomKey < Query
    def create(params)
      raise UnprocessableEntity unless Travis::API::V3::Models::CustomKey.where(name: params['name'], owner_id: params['owner_id'], owner_type: params['owner_type']).count.zero?

      if params['owner_type'] == 'User'
        org_ids = User.find(params['owner_id']).organizations.map(&:id)

        raise UnprocessableEntity unless Travis::API::V3::Models::CustomKey.where(name: params['name'], owner_id: org_ids, owner_type: 'Organization').count.zero?
      elsif params['owner_type'] == 'Organization'
        user_ids = Membership.where(organization_id: params['owner_id']).map(&:id)

        raise UnprocessableEntity unless Travis::API::V3::Models::CustomKey.where(name: params['name'], owner_id: user_ids, owner_type: 'User').count.zero?
      end

      key = Travis::API::V3::Models::CustomKey.new.save_key!(
        params['owner_type'],
        params['owner_id'],
        params['name'],
        params['description'],
        params['private_key'],
        params['added_by']
      )
      handle_errors(key) unless key.valid?

      key
    end

    def delete(params)
      Travis::API::V3::Models::CustomKey.find_by(id: params['id']).destroy
    end

    private

    def handle_errors(key)
      private_key = key.errors[:private_key]
      raise UnprocessableEntity if private_key.include?('invalid_pem')
      raise WrongParams         if private_key.include?('missing_attr')
    end
  end
end

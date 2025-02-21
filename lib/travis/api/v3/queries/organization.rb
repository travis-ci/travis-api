module Travis::API::V3
  class Queries::Organization < Query
    params :id, :login, :github_id, :provider

    def find
      return Models::Organization.find_by_id(id) if id
      return Models::Organization.find_by(vcs_id: github_id) || Models::Organization.find_by(github_id: github_id) if github_id
      return Models::Organization.where(
        'lower(login) = ? and lower(vcs_type) = ?'.freeze,
        login.downcase,
        provider.downcase + 'organization'
      ).order("id DESC").first if login
      raise WrongParams, 'missing organization.id or organization.login'.freeze
    end

    def update_billing_permission(user_id)
      data = params.dup.tap { |h| h.delete('organization.id') }
      client = BillingClient.new(user_id)
      client.update_organization_billing_permission(params['organization.id'], data)
    end

    def active(value, from)
      org = Models::Organization.find_by_id(id) if id
      from ||= Time.now - 1.day
      sort Models::User.where('id in (?)', org.memberships.pluck(:user_id)).where("users.last_activity_at #{value ? '>' : '<'}  ?", from)
    end

    def suspend(value)
      raise WrongParams, 'missing user ids'.freeze unless params['user_ids']&.size > 0

      filtered_ids = filter_ids
      Models::User.where("id in (?)", filtered_ids).update!(suspended: value, suspended_at: value ? Time.now.utc : nil)
      Models::BulkChangeResult.new(
        changed: filtered_ids,
        skipped: params['user_ids'] - filtered_ids
      )
    end

    def filter_ids
      Membership.where(organization_id: id, user_id: params['user_ids']).all.map(&:user_id)
    end

    private

    def provider
      params['provider'] || 'github'
    end

  end
end

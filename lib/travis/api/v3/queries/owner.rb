module Travis::API::V3
  class Queries::Owner < Query
    params :login, :github_id, :provider

    def find
      find!(:organization) || find!(:user)
    end

    def trial_allowed(user_id, owner_id, owner_type)
      client = BillingClient.new(user_id)
      !!client.trial_allowed(owner_id, owner_type)
    end

    private

    def query(type, main_type: self.main_type, params: self.params)
      main_type = type if main_type == :owner
      params['provider'] ||= 'github'
      params = params.merge("#{type}.login" => params['login']) if params['login']
      params = params.merge("#{type}.github_id" => params['github_id']) if params['github_id']
      Queries[type].new(params, main_type, service: @service)
    end

    def find!(type)
      query(type).find
    rescue WrongParams => e
    end
  end
end

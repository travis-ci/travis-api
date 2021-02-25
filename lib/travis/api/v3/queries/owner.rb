module Travis::API::V3
  class Queries::Owner < Query
    params :login, :github_id, :provider

    def find
      find!(:organization) || find!(:user)
    end

    private

    def query(type, main_type: self.main_type, params: self.params)
      main_type = type if main_type == :owner
      new_params = params.dup
      new_params.delete('github_id')
      new_params['provider'] ||= 'github'
      new_params["#{type}.login"] = params['login'] if params['login']
      new_params["#{type}.vcs_id"] = params['github_id'] if params['github_id']
      Queries[type].new(new_params, main_type, service: @service)
    end

    def find!(type)
      query(type).find
    rescue WrongParams => e
    end
  end
end

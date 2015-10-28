module Travis::API::V3
  class Queries::Owner < Query
    def find
      find!(:organization) || find!(:user)
    end

    private

    def query(type, main_type: self.main_type, params: self.params)
      main_type = type if main_type == :owner
      params    = params.merge("#{type}.login" => params["owner.login".freeze]) if params["owner.login".freeze]
      params    = params.merge("#{type}.github_id" => params["owner.github_id".freeze]) if params["owner.github_id".freeze]
      Queries[type].new(params, main_type, service: @service)
    end

    def find!(type)
      query(type).find
    rescue WrongParams => e
    end
  end
end

module Travis::API::V3
  class Queries::EnvVars < Query
    params :name, :value, :public, prefix: :env_var

    def find(repository)
      repository.env_vars
    end

    def create(repository)
      env_var = repository.env_vars.create(env_var_params)
      handle_errors(env_var) unless env_var.valid?
      repository.save!
      env_var
    end

    private

      def handle_errors(env_var)
        base = env_var.errors[:base]
        raise WrongParams       if base.include?(:format)
        raise DuplicateResource if base.include?(:duplicate_resource)
        raise ServerError
      end
  end
end

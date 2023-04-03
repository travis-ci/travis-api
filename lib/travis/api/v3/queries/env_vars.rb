module Travis::API::V3
  class Queries::EnvVars < Query
    params :name, :value, :public, :branch, prefix: :env_var

    def find(repository)
      repository.env_vars
    end

    def create(repository, from_admin)
      env_vars = repository.env_vars
      env_vars.user = repository.user_settings.user
      env_vars.change_source = 'travis-api' unless from_admin
      env_var = env_vars.create(env_var_params)
      unless env_var.valid?
        repository.env_vars.destroy(env_var.id)
        handle_errors(env_var)
      end
      repository.save!
      env_var
    end

    private

      def handle_errors(env_var)
        base = env_var.errors[:base]
        name = env_var.errors[:name]
        raise WrongParams       if base.include?(:format)
        raise DuplicateResource if base.include?(:duplicate_resource)
        raise UnprocessableEntity, 'Variable name is required' if name.include?(:blank)
        raise ServerError
      end
  end
end

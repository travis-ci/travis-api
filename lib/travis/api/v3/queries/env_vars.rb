module Travis::API::V3
  class Queries::EnvVars < Query
    params :name, :value, :public, :branch, prefix: :env_var

    def find(repository)
      repository.env_vars
    end

    def create(repository, from_admin = false)
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
        name = env_var.errors[:name]
        env_var.errors.each do |err|
          raise WrongParams       if err.details[:error] == :format
          raise DuplicateResource if err.details[:error] == :duplicate_resource
          raise UnprocessableEntity, 'Variable name is required' if (name&.include?(:blank) || name&.include?("can't be blank"))
        end

        raise ServerError
      end

      def errors_(env_var, what)
        env_var.errors.errors.any? { |e| e.type.to_s  == what}
      end
  end
end

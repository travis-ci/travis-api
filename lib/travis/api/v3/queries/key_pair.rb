module Travis::API::V3
  class Queries::KeyPair < Query
    params :description, :value, prefix: :key_pair

    def find(repository)
      repository.key_pair or raise EntityMissing.new(:key_pair)
    end

    def create(repository)
      raise DuplicateResource if repository.key_pair
      Models::KeyPair.new(key_pair_params.merge(repository_id: repository.id)).tap do |key_pair|
        handle_errors(key_pair) unless key_pair.valid?
        key_pair.sync_once(repository, :settings)
      end
    end

    def update(key_pair)
      key_pair.update(key_pair_params) or handle_errors(key_pair)
    end

    def delete(repository)
      key_pair = find(repository)
      key_pair.delete(repository)
    end

    private

    def handle_errors(key_pair)
      value = key_pair.errors[:value]
      if value.is_a?(Array)
        return value.each { |v| check_error(v) }
      end
      check_error(value)
    end

    def check_error(value)
      value = value.to_s
      raise UnprocessableEntity if value[/invalid_pem/]
      raise WrongParams if value[/missing_attr/]
    end
  end
end

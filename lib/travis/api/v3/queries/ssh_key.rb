module Travis::API::V3
  class Queries::SshKey < Query
    def find(repository)
      repository.key
    end

    def regenerate(repository)
      key = repository.key || repository.create_key
      key.tap { |key| key.generate_keys! }
    end
  end
end

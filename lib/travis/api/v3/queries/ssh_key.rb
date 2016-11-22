module Travis::API::V3
  class Queries::SshKey < Query
    def find(repository)
      repository.key
    end
  end
end

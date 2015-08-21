module Travis::API::V3
  class Queries::Builds < Query
    def find(repository)
      repository.builds
    end

    def count(repository, time_frame)
      find(repository).
        where(event_type: 'api'.freeze, result: 'accepted'.freeze).
        where('created_at > ?'.freeze, time_frame.ago).count
    end
  end
end

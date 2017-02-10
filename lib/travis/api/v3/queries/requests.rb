module Travis::API::V3
  class Queries::Requests < Query
    def find(repository)
      repository.requests
    end

    def count(repository, time_frame)
      find(repository).
        where(event_type: 'api'.freeze).
        where('created_at > ?'.freeze, time_frame.ago).count
    end
  end
end

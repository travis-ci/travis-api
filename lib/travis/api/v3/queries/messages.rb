module Travis::API::V3
  class Queries::Messages < Query
    def for_request(request)
      Models::Message.where(subject_type: "Request", subject_id: request.id).ordered
    end
  end
end

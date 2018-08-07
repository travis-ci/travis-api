module Travis::API::V3
  class Queries::Gdpr < Query
    def export(user_id)
      GdprClient.new(user_id).export
    end
  end
end

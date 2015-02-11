module Travis::API::V3
  class Services::Requests::Create < Service
    helpers :repository

    def run
      query.schedule_for(repository)
      accepted
    end
  end
end

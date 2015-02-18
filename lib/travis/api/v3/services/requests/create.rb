module Travis::API::V3
  class Services::Requests::Create < Service
    def run
      not_implemented
      query.schedule_for(find(:repository))
      accepted
    end
  end
end

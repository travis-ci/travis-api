module Travis::API::V3
  class Services::Messages::ForRequest < Service
    paginate

    def run!
      raise NotFound unless request = query(:request).find
      result query.for_request(request)
    end
  end
end

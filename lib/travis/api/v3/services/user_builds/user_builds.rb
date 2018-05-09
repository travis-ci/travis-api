module Travis::API::V3
  class Services::UserBuilds::ForCurrentUser < Service
    paginate(default_limit: 100)

    def run!
      result query.find
    end
  end
end

module Travis::API::V3
  class Services::Jobs::Find < Service
    paginate
    def run!
      query.find(find(:build))
    end
  end
end

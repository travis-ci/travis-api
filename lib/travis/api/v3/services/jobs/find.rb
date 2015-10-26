module Travis::API::V3
  class Services::Jobs::Find < Service
    def run!
      query.find(find(:build))
    end
  end
end

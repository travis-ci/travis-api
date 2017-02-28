module Travis::API::V3
  class Services::Jobs::Find < Service
    def run!
      result query.find(find(:build))
    end
  end
end

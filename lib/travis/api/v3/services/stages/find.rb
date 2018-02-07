module Travis::API::V3
  class Services::Stages::Find < Service
    def run!
      result query.find(find(:build))
    end
  end
end

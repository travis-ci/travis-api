module Travis::API::V3
  class Services::Branch::Find < Service
    def run!
      find(:branch, find(:repository))
    end
  end
end

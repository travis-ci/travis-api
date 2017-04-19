module Travis::API::V3
  class Services::Branch::Find < Service    
    def run!
      result find(:branch, find(:repository))
    end
  end
end

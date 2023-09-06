module Travis::API::V3
  class Services::RepositoryVcs::Find < Service
    def run!
      result find, type: :repository
    end
  end
end

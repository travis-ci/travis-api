module Travis::API::V3
  class Services::Repository::Find < Service
    params :by_vcs

    def run!
      result find
    end
  end
end

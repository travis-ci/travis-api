module Travis::API::V3
  class Services::Repository::Unstar < Service
    def run!
      super(true)
    end

    def check_access(repository)
      access_control.permissions(repository).unstar!
    end
  end
end

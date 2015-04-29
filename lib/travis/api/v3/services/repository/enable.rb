module Travis::API::V3
  class Services::Repository::Enable < Services::Repository::Disable
    def run!
      super(true)
    end

    def check_access(repository)
      access_control.permissions(repository).enable!
    end
  end
end

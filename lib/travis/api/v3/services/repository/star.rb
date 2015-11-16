module Travis::API::V3
  class Services::Repository::Star < Service
    def run!
      super(true)
    end

    def check_access(repository)
      access_control.permissions(repository).star!
    end
  end
end

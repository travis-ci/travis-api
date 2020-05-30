module Travis::API::V3
  class Services::Build::Priority < Service

    def run
      #Need to add code for permission
      #Add code to set query from here.
      build = check_login_and_find(:build)
      accepted(build: build, priority: true)
    end
  end
end

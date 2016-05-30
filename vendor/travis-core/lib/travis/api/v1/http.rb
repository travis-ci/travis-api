module Travis
  module Api
    module V1
      module Http
        require 'travis/api/v1/http/branches'
        require 'travis/api/v1/http/build'
        require 'travis/api/v1/http/builds'
        require 'travis/api/v1/http/hooks'
        require 'travis/api/v1/http/job'
        require 'travis/api/v1/http/jobs'
        require 'travis/api/v1/http/repositories'
        require 'travis/api/v1/http/repository'
        require 'travis/api/v1/http/user'
      end
    end
  end
end

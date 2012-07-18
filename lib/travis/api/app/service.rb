module Travis
  module Api
    class App
      class Service
        autoload :Artifacts, 'travis/api/app/service/artifacts'
        autoload :Builds,    'travis/api/app/service/builds'
        autoload :Hooks,     'travis/api/app/service/hooks'
        autoload :Jobs,      'travis/api/app/service/jobs'
        autoload :Repos,     'travis/api/app/service/repos'
        autoload :Workers,   'travis/api/app/service/workers'

        attr_reader :params

        def initialize(params)
          @params = params
        end
      end
    end
  end
end

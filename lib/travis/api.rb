module Travis
  require 'travis/setup'
  require 'travis/features'

  module API
    require 'travis/api/v3'
    require 'travis/api/cors'
    require 'travis/api/response_cleaner'
    require 'travis/api/app'
  end

  Api = API
end

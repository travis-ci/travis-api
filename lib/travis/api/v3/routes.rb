module Travis::API::V3
  module Routes
    require 'travis/api/v3/routes/dsl'
    extend DSL

    resource :repository do
      get :find_repository
    end
  end
end

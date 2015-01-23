module Travis::API::V3
  module Routes
    require 'travis/api/v3/routes/dsl'
    extend DSL

    resource :repository do
      route '/repo/{repository.id}'
      get :find_repository
    end

    resource :repositories do
      route '/repos'
      get :repositories_for_current_user
    end
  end
end

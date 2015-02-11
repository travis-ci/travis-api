module Travis::API::V3
  module Routes
    require 'travis/api/v3/routes/dsl'
    extend DSL

    resource :repository do
      route '/repo/{repository.id}'
      get :find

      resource :requests do
        route '/requests'
        get  :find
        post :create
      end
    end

    resource :repositories do
      route '/repos'
      get :for_current_user
    end

    resource :organizations do
      route '/orgs'
      get :for_current_user
    end
  end
end

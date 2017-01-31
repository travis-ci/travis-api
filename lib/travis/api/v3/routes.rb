module Travis::API::V3
  module Routes
    require 'travis/api/v3/routes/dsl'
    extend DSL

    resource :accounts do
      route '/accounts'
      get :for_current_user
    end

    resource :broadcasts do
      route '/broadcasts'
      get :for_current_user
    end

    resource :build do
      capture id: :digit
      route '/build/{build.id}'
      get :find

      post :cancel, '/cancel'
      post :restart, '/restart'

      resource :jobs do
        route '/jobs'
        get  :find
      end
    end


    resource :cron do
      capture id: :digit
      route '/cron/{cron.id}'
      get :find
      delete :delete
    end

    resource :job do
      capture id: :digit
      route '/job/{job.id}'
      get :find

      post :cancel, '/cancel'
      post :restart, '/restart'
      post :debug, '/debug'

      resource :log do
        route '/log'
        get   :find
        delete :delete
      end

    end

    resource :lint do
      route '/lint'
      post :lint
    end

    resource :organization do
      capture id: :digit
      route '/org/{organization.id}'
      get :find
    end

    resource :organizations do
      route '/orgs'
      get :for_current_user
    end

    resource :owner do
      route '/owner/({owner.login}|{user.login}|{organization.login}|github_id/{owner.github_id})'
      get :find

      resource :repositories do
        route '/repos'
        get :for_owner
      end

      resource :active do
        route '/active'
        get :for_owner
      end
    end

    resource :repositories do
      route '/repos'
      get :for_current_user
    end

    resource :repository do
      capture id: :digit, slug: %r{[^/]+%2[fF][^/]+}
      route '/repo/({repository.id}|{repository.slug})'
      get :find

      post :activate,  '/activate'
      post :deactivate, '/deactivate'
      post :star,    '/star'
      post :unstar,  '/unstar'

      resource :branch do
        route '/branch/{branch.name}'
        get :find

        resource :cron do
          route '/cron'
          get  :for_branch
          post :create
        end
      end

      resource :branches do
        route '/branches'
        get :find
      end

      resource :builds do
        route '/builds'
        get  :find
      end

      resource :caches do
        route '/caches'
        get :find
        delete :delete
      end

      resource :crons do
        route '/crons'
        get  :for_repository
      end

      resource :requests do
        route '/requests'
        get  :find
        post :create
      end

      resource :user_settings do
        route '/settings'
        get   :find
      end

      resource :user_setting do
        route '/setting/{user_setting.name}'
        get  :find
        patch :update
      end

      resource :env_vars do
        route '/env_vars'
        get   :for_repository
        post  :create
      end

      resource :env_var do
        route  '/env_var/{env_var.id}'
        get    :find
        patch  :update
        delete :delete
      end

      resource :ssh_key do
        route '/ssh_key'
        get   :find
        post  :create
      end
    end

    resource :user do
      capture id: :digit
      route '/user'
      get :current
      get :find, '/{user.id}'
      post :sync, '/{user.id}/sync'
    end

  end
end

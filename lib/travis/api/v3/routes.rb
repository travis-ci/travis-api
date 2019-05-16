module Travis::API::V3
  module Routes
    require 'travis/api/v3/routes/dsl'
    extend DSL

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

      resource :stages do
        route '/stages'
        get   :find
      end
    end

    resource :builds do
      route '/builds'
      get :for_current_user
    end

    resource :jobs do
      route '/jobs'
      get :for_current_user
    end

    resource :cron do
      capture id: :digit
      route '/cron/{cron.id}'
      get :find
      delete :delete
    end

    enterprise do
      resource :enterprise_license do
        get :find
        route '/enterprise_license'
      end
    end

    resource :installation do
      route '/installation/{installation.github_id}'
      get :find
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
        get   :find, '.txt'
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

      resource :preferences do
        route '/preferences'
        get :for_organization
      end

      resource :preference do
        route '/preference/{preference.name}'
        get   :for_organization
        patch :update
      end
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

      post :activate, '/activate'
      post :deactivate, '/deactivate'
      post :migrate, '/migrate'
      post :star, '/star'
      post :unstar, '/unstar'
      hide(patch :update)

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

      resource :request do
        route '/request/{request.id}'
        get  :find

        resource :messages do
          route '/messages'
          get :for_request
        end
      end

      resource :user_settings, as: :settings do
        route '/settings'
        get   :for_repository
      end

      resource :user_setting, as: :setting do
        route '/setting/{setting.name}'
        get   :find
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

      # This is the key we generate for encryption/decryption etc.
      # In V2 it was found at /repos/:repo_id/key
      resource :ssl_key, as: :key_pair_generated do
        route '/key_pair/generated'
        get   :find
        post  :create
      end

      # This is the key that users may choose to add on travis-ci.com
      # In V2 it was found at /settings/ssh_key/:repo_id
      resource :key_pair do
        route   '/key_pair'
        get     :find
        post    :create
        patch   :update
        delete :delete
      end

      resource :email_subscription do
        route '/email_subscription'
        delete :unsubscribe
        post :resubscribe
      end
    end

    resource :user do
      capture id: :digit
      route '/user/{user.id}'
      get :find
      post :sync, '/sync'

      resource :beta_features do
        route '/beta_features'
        get   :find
      end

      resource :beta_feature do
        route  '/beta_feature/{beta_feature.id}'
        patch  :update
        delete :delete
      end

      resource :beta_migration_requests do
        route '/beta_migration_requests'
        get    :proxy_find
      end

      resource :beta_migration_request do
        route '/beta_migration_request'
        post   :proxy_create
      end
    end

    hidden_resource :beta_migration_requests do
      route '/beta_migration_requests'

      get    :find
      post   :create
    end

    resource :user do
      route '/user'
      get :current
    end

    resource :preferences do
      route '/preferences'
      get   :for_user
    end

    resource :preference do
      route '/preference/{preference.name}'
      get   :find
      patch :update
    end

    if ENV['BILLING_V2_ENABLED']
      hidden_resource :subscriptions do
        route '/subscriptions'
        get :all
        post :create
      end

      hidden_resource :subscription do
        route '/subscription/{subscription.id}'
        patch :update_address, '/address'
        patch :update_creditcard, '/creditcard'
        patch :update_plan, '/plan'
        patch :resubscribe, '/resubscribe'
        post :cancel, '/cancel'
        get :invoices, '/invoices'
      end

      hidden_resource :trials do
        route '/trials'
        get :all
      end

      hidden_resource :plans do
        route '/plans'
        get :all
      end
    end

    if ENV['GDPR_ENABLED']
      hidden_resource :gdpr do
        route '/gdpr'
        post :export, '/export'
        delete :purge, '/purge'
      end
    end

    hidden_resource :insights do
      route '/insights'
      get :metrics, '/metrics'
      get :active_repos, '/repos/active'
    end
  end
end

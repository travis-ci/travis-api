module Travis::API::V3
  module Routes
    require 'travis/api/v3/routes/dsl'
    extend DSL

    resource :access_token do
      route '/access_token'

      patch :regenerate_token
      delete :remove_token
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
      post :priority, '/priority'

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

    resource :build_backups do
      route '/build_backups'
      get :all
    end

    resource :build_backup do
      route '/build_backup/{build_backup.id}'
      get :find
      get :find, '.txt'
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
      patch :update_billing_permission, '/update_billing_permission'

      resource :preferences do
        route '/preferences'
        get :for_organization
      end

      resource :preference do
        route '/preference/{preference.name}'
        get   :for_organization
        patch :update
      end

      resource :build_permissions do
        route '/build_permissions'
        get :find_for_organization
        patch :update_for_organization
      end

      resource :email_subscription do
        route '/email_subscription'
        delete :unsubscribe
        post :resubscribe
      end
    end

    resource :organizations do
      route '/orgs'
      get :for_current_user
    end

    resource :owner do
      route '/owner/(github_id/{github_id}|({provider}/)?{login})'
      get :find

      resource :repositories do
        route '/repos'
        get :for_owner
      end

      resource :active do
        route '/active'
        get :for_owner
      end

      resource :allowance do
        route '/allowance'
        get :for_owner
      end

      resource :executions do
        route '/executions'
        get :for_owner
      end

      resource :executions do
        route '/executions_per_repo'
        get :for_owner_per_repo
      end

      resource :executions do
        route '/executions_per_sender'
        get :for_owner_per_sender
      end
    end

    resource :credits_calculator do
      route '/credits_calculator'
      post :calculator
      get :default_config
    end

    resource :repositories do
      route '/repos'
      get :for_current_user
    end

    resource :repository do
      capture id: :digit, slug: %r{[^/]+%2[fF][^/]+}
      route '/repo/({provider}/)?({repository.id}|{repository.slug})'
      get :find

      post :activate, '/activate'
      post :deactivate, '/deactivate'
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

      resource :build_permissions do
        route '/build_permissions'
        get :find_for_repo
        patch :update_for_repo
      end

      resource :branches do
        route '/branches'
        get :find
      end

      resource :builds do
        route '/builds'
        get :find
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
        hide(post :preview)
        post :preview

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

    hidden_resource :repository_vcs do
      route '/repo_vcs/{provider}/{repository_vcs.vcs_id}'
      get :find
    end

    unless ENV['SCANNER_DISABLED']
      resource :scan_results do
        route '/scan_results'
        get :all
      end

      resource :scan_result do
        route '/scan_result/{scan_result.id}'
        get :find
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

    hidden_resource :custom_keys do
      route '/custom_keys'
      post   :create
    end

    hidden_resource :custom_key do
      route '/custom_key/{id}'
      delete   :delete
    end

    hidden_resource :storage do
      route  '/storage/{id}'
      get    :find
      patch  :update
      delete :delete
    end

    hidden_resource :beta_migration_requests do
      route '/beta_migration_requests'

      get    :find
      post   :create
    end

    resource :user do
      route '/user'
      get :current
      patch :update
    end

    resource :user do
      route '/logout'
      get :logout
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

    hidden_resource :subscriptions do
      route '/subscriptions'
      get :all
      post :create
    end

    hidden_resource :v2_subscriptions do
      route '/v2_subscriptions'
      get :all
      post :create
    end

    hidden_resource :subscription do
      route '/subscription/{subscription.id}'
      patch :update_payment_details, '/payment_details'
      patch :update_address, '/address'
      patch :update_creditcard, '/creditcard'
      patch :update_plan, '/plan'
      patch :resubscribe, '/resubscribe'
      post :cancel, '/cancel'
      post :pause, '/pause'
      post :pay, '/pay'
      get :invoices, '/invoices'
    end

    hidden_resource :v2_subscription do
      route '/v2_subscription/{subscription.id}'
      patch :update_payment_details, '/payment_details'
      patch :update_address, '/address'
      patch :update_creditcard, '/creditcard'
      patch :changetofree, '/changetofree'
      patch :update_plan, '/plan'
      post :pay, '/pay'
      post :cancel, '/cancel'
      post :pause, '/pause'
      post :buy_addon, '/addon/{addon.id}'
      get :user_usages, '/user_usages'
      get :invoices, '/invoices'
      get :auto_refill, '/auto_refill'
      patch :toggle_auto_refill,  '/auto_refill'
      patch :update_auto_refill, '/update_auto_refill'
    end

    hidden_resource :trials do
      route '/trials'
      get :all
      post :create
    end

    hidden_resource :coupons do
      route '/coupons/{coupon.id}'
      get :find
    end

    hidden_resource :plans do
      route '/plans_for'
      get :all, '/user'
      get :all, '/organization/{organization.id}'
    end

    hidden_resource :v2_plans do
      route '/v2_plans_for'
      get :all, '/user'
      get :all, '/organization/{organization.id}'

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

    hidden_resource :queues do
      route '/queues/{queue.name}'
      get :stats, '/stats'
    end

  end
end

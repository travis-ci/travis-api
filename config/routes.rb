Rails.application.routes.draw do
  root 'home#home'

  get 'admins', to: 'users#admins', as: :admins

  resources :audit_trail, only: [:index]

  resources :broadcasts, only: [:index, :create, :update]

  resources :builds, only: [:show] do
    member do
      post 'cancel'
      post 'restart'
    end
  end

  resources :features, only: [:index], param: :feature do
    member do
      post 'disable'
      post 'enable'
    end
  end
  get 'features/:kind/:feature', to: 'features#show', as: :feature

  get 'help', to: 'search#help'

  resources :jobs, only: [:show] do
    member do
      post 'cancel'
      post 'restart'
    end
  end

  get 'logout', to: 'home#logout', as: :logout

  get 'not_found', to: 'home#not_found', as: :not_found

  resources :offenders, only: [:index, :update], param: :login

  resources :organizations, only: [:show] do
    member do
      post 'boost'
      post 'features'
      post 'update_trial_builds'

      get 'subscription'
      get 'invoices'
      get 'members'
      get 'repositories'
      get 'jobs'
      get 'requests'
      get 'broadcasts'
    end
  end

  resources :repositories, only: [:show] do
    member do
      post 'add_hook_event'
      post 'check_hook'
      post 'delete_last_build'
      post 'disable'
      post 'enable'
      post 'features'
      post 'set_hook_url'
      post 'settings', to: 'settings#update', as: :repository_settings
      post 'test_hook'

      get  'broadcasts'
      get  'builds'
      get  'caches'
      get  'requests'
      get  'users'
    end
  end

  post 'repositories/:id/caches/delete' => 'caches#delete_all', as: :delete_all_caches
  post 'repositories/:id/caches/:branch/delete' => 'caches#delete', constraints: { branch: /.*/ }, as: :delete_branch_cache

  resources :requests, only: [:show]

  get 'search', to: 'search#search'

  resources :subscriptions,  only: [:create, :update]

  resources :users, only: [:show] do
    member do
      post 'boost'
      post 'display_token'
      post 'features'
      post 'hide_token'
      post 'reset_2fa'
      post 'sync'
      post 'reset_sync'
      post 'update_trial_builds'
      post 'suspend'
      post 'unsuspend'

      get 'subscription'
      get 'invoices'
      get 'organizations'
      get 'repositories'
      get 'jobs'
      get 'requests'
      get 'broadcasts'
    end

    post 'sync_all', on: :collection
  end

  resources :enterprise_users, only: [:index] do
    member do
      post 'suspend'
      post 'unsuspend'
    end
  end
end

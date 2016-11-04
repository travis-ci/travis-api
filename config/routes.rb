Rails.application.routes.draw do
  root 'home#home'

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
  get 'features/:kind/:feature' => 'features#show', as: :feature

  resources :jobs, only: [:show] do
    member do
      post 'cancel'
      post 'restart'
    end
  end

  resources :offenders, only: [:index, :update], param: :login

  resources :organizations, only: [:show] do
    member do
      post 'update_trial_builds'
      post 'boost'
      post 'features'
    end
  end

  resources :repositories, only: [:show] do
    member do
      post 'enable'
      post 'disable'
      post 'features'
      post 'settings', to: 'settings#update', as: :repository_settings
    end
  end

  resources :requests, only: [:show]

  resources :subscriptions,  only: [:create, :update]

  resources :users, only: [:show] do
    member do
      post 'boost'
      post 'display_token'
      post 'features'
      post 'reset_2fa'
      post 'sync'
      post 'update_trial_builds'
    end
    post 'sync_all', on: :collection
  end

  get 'admins' => 'users#admins', as: :admins

  get 'logout' => 'home#logout', as: :logout
  get 'not_found' => 'home#not_found', as: :not_found

  get 'search', to: 'search#search'
  get 'help',   to: 'search#help'
end

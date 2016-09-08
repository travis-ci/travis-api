Rails.application.routes.draw do
  root 'home#home'

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

  resources :event_logs, only: [:index]

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

  resources :subscriptions,  only: [:show, :update]

  resources :users, only: [:show] do
    member do
      post 'sync'
      post 'update_trial_builds'
      post 'boost'
      post 'features'
    end
    post 'sync_all', on: :collection
  end

  get 'admins' => 'users#admins', as: :admins
end

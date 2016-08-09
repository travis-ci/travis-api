Rails.application.routes.draw do
  root 'home#home'

  resources :offenders,  only: [:index, :update]
  resources :broadcasts, only: [:index, :create, :update]

  get 'user/:id' => 'users#show', as: :user
  post 'user/:id/sync' => 'users#sync', as: :sync_user
  post 'user/sync_all' => 'users#sync_all', as: :sync_all
  post 'user/:id/update_trial_builds' => 'users#update_trial_builds', as: :user_update_trial_builds

  get 'organization/:id' => 'organizations#show', as: :organization
  post 'organization/:id/update_trial_builds' => 'organizations#update_trial_builds', as: :organization_update_trial_builds

  get 'repository/:id' => 'repositories#show', as: :repository
  post 'repository/:id/enable' => 'repositories#enable', as: :enable_repository
  post 'repository/:id/disable' => 'repositories#disable', as: :disable_repository

  get 'request/:id' => 'requests#show', as: :request

  get 'build/:id' => 'builds#show', as: :build
  post 'build/:id/cancel' => 'builds#cancel', as: :cancel_build
  post 'build/:id/restart' => 'builds#restart', as: :restart_build

  get 'job/:id' => 'jobs#show', as: :job
  post 'job/:id/cancel' => 'jobs#cancel', as: :cancel_job
  post 'job/:id/restart' => 'jobs#restart', as: :restart_job

  get 'subscription/:id' => 'subscriptions#show', as: :subscription

  get 'admins' => 'users#admins', as: :admins
end

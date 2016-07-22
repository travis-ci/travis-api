Rails.application.routes.draw do
  root 'home#home'

  get 'user/:id' => 'users#show', as: :user
  post 'user/:id/sync' => 'users#sync', as: :sync_user
  post 'user/sync_all' => 'users#sync_all', as: :sync_all

  get 'organization/:id' => 'organizations#show', as: :organization

  get 'repository/:id' => 'repositories#show', as: :repository
  post 'repository/:id/enable' => 'repositories#enable', as: :enable_repository
  post 'repository/:id/disable' => 'repositories#disable', as: :disable_repository

  get 'request/:id' => 'requests#show', as: :request
  get 'build/:id' => 'builds#show', as: :build
  get 'job/:id' => 'jobs#show', as: :job
  get 'subscription/:id' => 'subscriptions#show', as: :subscription
  get 'broadcast' => 'broadcasts#index', as: :broadcast
end

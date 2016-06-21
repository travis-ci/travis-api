Rails.application.routes.draw do
  root 'home#home'

  get 'user/:id' => 'users#show', as: :user
  get 'organization/:id' => 'organizations#show', as: :organization
end

Rails.application.routes.draw do
  get 'user/:id' => 'users#show', as: :user
  get 'organization/:id' => 'organizations#show', as: :organization
end

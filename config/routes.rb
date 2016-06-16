Rails.application.routes.draw do
  get 'user/:id' => 'users#show'
  get 'organization/:id' => 'organizations#show'
end

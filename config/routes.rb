Rails.application.routes.draw do

  # root

  # resources :subscriptions do
  # end

  get 'user/:id' => 'users#show'
end

Rails.application.routes.draw do
  get 'user/:id' => 'users#show'
end

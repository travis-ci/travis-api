  # api = lambda do
  #   constraints :format => 'json' do
  #     resources :repositories, :only => [:index, :show]
  #     resources :builds,       :only => [:index, :show]
  #     resources :branches,     :only => :index
  #     resources :jobs,         :only => [:index, :show]
  #     resources :workers,      :only => :index

  #     get 'service_hooks',     :to => 'service_hooks#index'
  #     put 'service_hooks/:id', :to => 'service_hooks#update', :id => /[\w-]*:[\w.-]*/
  #   end

  #   constraints :owner_name => /[^\/]+/, :name => /[^\/]+/ do
  #     get ':owner_name/:name.json',            :to => 'repositories#show', :format => :json
  #     get ':owner_name/:name/builds.json',     :to => 'builds#index',      :format => :json
  #     get ':owner_name/:name/builds/:id.json', :to => 'builds#show',       :format => :json
  #     get ':owner_name/:name.png',             :to => 'repositories#show', :format => :png
  #     get ':owner_name/:name/cc.xml',          :to => 'repositories#show', :format => :xml, :schema => 'cctray'
  #   end
  # end


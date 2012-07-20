require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'travis'

Travis::Database.connect

module Travis
  module Api
    class App < Sinatra::Application
      autoload :Service, 'travis/api/app/service'

      use ActiveRecord::ConnectionAdapters::ConnectionManagement

      error ActiveRecord::RecordNotFound do
        not_found
      end

      configure :development do
        register Sinatra::Reloader
        set :show_exceptions, :after_handler
      end

      provides :json

      get '/repositories' do
        respond_with Service::Repos.new(params).collection
      end

      get '/repositories/:id' do
        respond_with Service::Repos.new(params).item
        #   raise if not params[:format] == 'png'
      end

      get '/builds' do
        respond_with Service::Builds.new(params).collection
      end

      get '/builds/:id' do
        respond_with Service::Builds.new(params).item
      end

      get '/branches' do
        # respond_with Service::Repos.new(params).item, :type => :branches
        { branches: [] }.to_json
      end

      get '/jobs' do
        respond_with Service::Jobs.new(params).collection
      end

      get '/jobs/:id' do
        respond_with Service::Jobs.new(params).item
      end

      get '/artifacts/:id' do
        respond_with Service::Artifacts.new(params).item
      end

      get '/workers' do
        respond_with Service::Workers.new(params).collection
      end

      get '/hooks' do
        authenticate_user!
        respond_with Service::Hooks.new(user, params).item
        # rescue_from ActiveRecord::RecordInvalid, :with => Proc.new { head :not_acceptable }
      end

      put '/hooks/:id' do
        authenticate_user!
        respond_with Service::Hooks.new(user, params).update
      end

      get '/profile' do
        authenticate_user!
        respond_with Service::Profile.new(user).update
      end

      post '/profile/sync' do
        authenticate_user!
        respond_with Service::Profile.new(user).sync
      end

      private

        def authenticate_user!
          @user = User.find_by_login('svenfuchs')
        end

        def respond_with(resource, params = {})
          Travis::Api.data(resource, :params => self.params.merge(params), :version => version).to_json
        end

        def version
          'v2'
        end
    end
  end
end

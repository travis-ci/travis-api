require 'travis/api/app'

class Travis::Api::App
  module Extensions
    module Scoping
      module Helpers
        def access_token
          env['travis.access_token']
        end

        def user
          access_token.user if logged_in?
        end

        def logged_in?
          !!access_token
        end

        def scopes
          logged_in? ? access_token.scopes : settings.anonymous_scopes
        end
      end

      def self.registered(app)
        app.set default_scope: :public, anonymous_scopes: [:public]
        app.helpers(Helpers)
      end

      def scope(name)
        condition do
          name = settings.default_scope if name == :default
          headers['X-OAuth-Scopes'] = scopes.map(&:to_s).join(',')
          headers['X-Accepted-OAuth-Scopes'] = name.to_s
          scopes.include? name
        end
      end

      def route(verb, path, options = {}, &block)
        options[:scope] ||= :default
        super(verb, path, options, &block)
      end
    end
  end
end

require 'travis/api/app'

class Travis::Api::App
  module Extensions
    module Scoping
      module Helpers
        def scope
          env['travis.scope'].to_sym
        end

        def public?
          scope == :public
        end
      end

      def self.registered(app)
        app.set default_scope: :public, anonymous_scopes: [:public]
        app.helpers(Helpers)
      end

      def scope(name)
        condition do
          name   = settings.default_scope if name == :default
          scopes = env['travis.access_token'].try(:scopes) || settings.anonymous_scopes
          headers['X-OAuth-Scopes'] = scopes.map(&:to_s).join(',')
          headers['X-Accepted-OAuth-Scopes'] = name.to_s

          if scopes.include? name
            env['travis.scope'] = name
            headers['Vary'] = 'Accept'
            headers['Vary'] << ', Authorization' unless public?
            true
          elsif env['travis.access_token']
            pass { halt 403, "insufficient access" }
          else
            pass { halt 401, "no access token supplied" }
          end
        end
      end

      def route(verb, path, options = {}, &block)
        options[:scope] ||= :default
        super(verb, path, options, &block)
      end
    end
  end
end

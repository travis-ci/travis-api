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

        def required_params_match?
          return true unless token = env['travis.access_token']

          if token.extra && (required_params = token.extra['required_params'])
            required_params.all? { |name, value| params[name] == value }
          else
            true
          end
        end
      end

      def self.registered(app)
        app.set default_scope: :public, anonymous_scopes: [:public]
        app.helpers(Helpers)
      end

      def scope(*names)
        condition do
          names  = [settings.default_scope] if names == [:default]
          scopes = env['travis.access_token'].try(:scopes) || settings.anonymous_scopes

          result = names.any? do |name|
            if scopes.include?(name) && required_params_match?
              headers['X-OAuth-Scopes'] = scopes.map(&:to_s).join(',')
              headers['X-Accepted-OAuth-Scopes'] = name.to_s

              env['travis.scope'] = name
              headers['Vary'] = 'Accept'
              headers['Vary'] << ', Authorization' unless public?
              true
            end
          end

          if !result
            headers['X-OAuth-Scopes'] = scopes.map(&:to_s).join(',')
            headers['X-Accepted-OAuth-Scopes'] = names.first.to_s

            if env['travis.access_token']
              pass { halt 403, "insufficient access" }
            else
              pass { halt 401, "no access token supplied" }
            end
          end

          result
        end
      end

      def route(verb, path, options = {}, &block)
        options[:scope] ||= :default
        super(verb, path, options, &block)
      end
    end
  end
end

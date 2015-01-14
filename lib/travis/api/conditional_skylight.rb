# if ENV['SKYLIGHT_AUTHENTICATION']
#
#   # require 'skylight/sinatra'
#   # require 'tool/thread_local'
#   # Skylight.start!
#   #
#   # module Travis
#   #   module Api
#   #     module ConditionalSkylight
#   #       FEATURES        = Tool::ThreadLocal.new
#   #       CHECK_FREQUENCY = 120
#   #       NOT_JSON        = %r(\.(xml|png|txt|atom|svg)$)
#   #
#   #       module Middleware
#   #         ::Skylight::Middleware.send(:prepend, self)
#   #         def call(env)
#   #           if ConditionalSkylight.track?(env)
#   #             super(env)
#   #           else
#   #             t { "skipping middleware (condition not met)".freeze }
#   #             @app.call(env)
#   #           end
#   #         end
#   #       end
#   #
#   #       extend self
#   #
#   #       def track?(env)
#   #         return false unless feature_active? :skylight
#   #         return false if     feature_active? :skylight_json_only and env['PATH_INFO'.freeze] =~ NOT_JSON
#   #         true
#   #       end
#   #
#   #       def feature_active?(feature)
#   #         last_clear = Time.now.to_i - FEATURES[:last_clear].to_i
#   #
#   #         if last_clear > CHECK_FREQUENCY
#   #           FEATURES.clear
#   #           FEATURES[:last_clear] = Time.now.to_i
#   #         end
#   #
#   #         FEATURES.fetch(feature) { FEATURES[feature] = Travis::Features.feature_active?(feature) }
#   #       end
#   #     end
#   #   end
#   # end
#
# else
#   Travis.logger.info('SKYLIGHT_AUTHENTICATION not set, skipping Skylight.')
# end

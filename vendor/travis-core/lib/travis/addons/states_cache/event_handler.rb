require 'travis/event/handler'

module Travis
  module Addons
    module StatesCache
      class EventHandler < Event::Handler
        EVENTS = /build:finished/

        def handle?
          states_cache_enabled = Travis::Features.feature_active?(:states_cache)
          result = !pull_request? && states_cache_enabled
          Travis.logger.info("[states-cache] Checking if event handler should be run for " +
            "repo_id=#{repository_id} branch=#{branch} build_id=#{build['id']}, result: #{result}, " +
            "pull_request: #{pull_request?} states_cache_enabled: #{states_cache_enabled}")
          result
        end

        def handle
          Travis.logger.info("[states-cache] Running event handler for repo_id=#{repository_id} build_id=#{build['id']} branch=#{branch}")
          cache.write(repository_id, branch, data)
        rescue Exception => e
          Travis.logger.error("[states-cache] An error occurred while trying to handle states cache update: #{e.message}\n#{e.backtrace}")
          raise
        end

        def cache
          Travis.states_cache
        end

        def repository_id
          build['repository_id']
        end

        def branch
          commit['branch']
        end

        def data
          {
            'id'    => build['id'],
            'state' => build['state']
          }
        end
      end
    end
  end
end

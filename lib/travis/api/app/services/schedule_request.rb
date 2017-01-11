require 'multi_json'
require 'travis/sidekiq/build_request'
require 'travis/services/base'

class Travis::Api::App
  module Services
    class ScheduleRequest < Travis::Services::Base
      register :schedule_request

      def run
        if repo.nil?
          not_found
        elsif !active?
          not_active
        elsif throttle.throttled?
          throttled
        else
          schedule_request
        end
      end

      def messages
        @messages ||= []
      end

      private

        def schedule_request
          Metriks.meter('api.request.create').mark
          Travis::Sidekiq::BuildRequest.perform_async(type: 'api', payload: payload, credentials: {})
          messages << { notice: 'Build request scheduled.' }
          :success
        end

        def not_found
          messages << { error: "Repository #{slug} not found." }
          :not_found
        end

        def not_active
          messages << { error: "Repository #{slug} not active." }
          :not_active
        end

        def throttled
          messages << { error: "Repository #{slug} throttled." }
          :throttled
        end

        def active?
          Travis::Features.owner_active?(:request_create, repo.owner)
        end

        def payload
          data = params.merge(user: { id: current_user.id })
          data[:repository][:id] = repo.github_id
          MultiJson.encode(data)
        end

        def repo
          instance_variable_defined?(:@repo) ? @repo : @repo = Repository.by_slug(slug).first
        end

        def slug
          repo = params[:repository] || {}
          repo.values_at(:owner_name, :name).join('/')
        end

        def throttle
          @throttle ||= Throttle.new(slug)
        end

        class Throttle < Struct.new(:slug)
          def throttled?
            current_requests >= max_requests
          end

          def message
            'API throttled'
          end

          private

            def current_requests
              @current_requests ||= begin
                sql = "repository_id = ? AND event_type = ? AND result = ? AND created_at > ?"
                Request.where(sql, repository.id, 'api', 'accepted', 1.hour.ago).count
              end
            end

            def max_requests
              Travis.config.max_api_requests || 10
            end

            def repository
              @repository ||= Repository.by_slug(slug).first || raise(RepositoryNotFoundError.new(slug: slug))
            end
        end
    end
  end
end

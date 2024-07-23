require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Logs < Endpoint
      before { authenticate_by_mode! }

      get '/:id' do |id|
        resource = service(:find_log, id: params[:id]).run
        job = resource ? Job.find(resource.job_id) : nil

        halt 404 unless job


        repo = Travis::API::V3::Models::Repository.find(job.repository.id)

        auth_for_repo(repo.id, 'repository_log_view') unless Travis.config.legacy_roles

        repo_can_write = current_user ? !!repo.users.where(id: current_user.id, permissions: { push: true }).first : false

        if !repo.user_settings.job_log_time_based_limit && job.started_at && job.started_at < Time.now - repo.user_settings.job_log_access_older_than_days.days
          halt 403, { error: { message: "We're sorry, but this data is not available anymore. Please check the repository settings in Travis CI." } }
        end

        if repo.user_settings.job_log_access_based_limit && !repo_can_write
          halt 403, { error: { message: "We're sorry, but this data is not available. Please check the repository settings in Travis CI." } }
        end

        if !resource || ((job.try(:private?) || !allow_public?) && !has_permission?(job))
          halt 404
        elsif resource.removed_at && accepts?('application/json')
          respond_with resource
        elsif resource.archived?
          # the way we use responders makes it hard to validate proper format
          # automatically here, so we need to check it explicitly
          if accepts?('text/plain')
            respond_with resource.archived_log_content
          elsif accepts?('application/json')
            respond_with resource.as_json
          else
            status 406
          end
        else
          respond_with resource, type: :remote_log
        end
      end

      def has_permission?(job)
        current_user && Permission.where(user: current_user, repository_id: job.repository_id).first
      end

      def archive_url(path)
        "https://s3.amazonaws.com/#{hostname('archive')}#{path}"
      end
    end
  end
end

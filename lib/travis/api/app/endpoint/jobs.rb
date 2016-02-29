require 'travis/api/app'
require 'travis/api/workers/job_cancellation'
require 'travis/api/workers/job_restart'

class Travis::Api::App
  class Endpoint
    class Jobs < Endpoint
      include Helpers::Accept

      get '/' do
        prefer_follower do
          respond_with service(:find_jobs, params)
        end
      end

      get '/:id' do
        job = service(:find_job, params).run
        if job && job.repository
          respond_with job
        else
          json = { error: { message: "The job(#{params[:id]}) couldn't be found" } }
          status 404
          respond_with json
        end
      end

      post '/:id/cancel' do
        Metriks.meter("api.request.cancel_job").mark

        service = self.service(:cancel_job, params.merge(source: 'api'))
        if !service.authorized?
          json = { error: {
            message: "You don't have access to cancel job(#{params[:id]})"
          } }

          Metriks.meter("api.request.cancel_job.unauthorized").mark
          status 403
          respond_with json
        elsif !service.can_cancel?
          json = { error: {
            message: "The job(#{params[:id]}) can't be canceled",
              code: 'cant_cancel'
          } }

          Metriks.meter("api.request.cancel_job.cant_cancel").mark
          status 422
          respond_with json
        else
          Travis::Sidekiq::JobCancellation.perform_async(id: params[:id], user_id: current_user.id, source: 'api')

          Metriks.meter("api.request.cancel_job.success").mark
          status 204
        end
      end

      post '/:id/restart' do
        Metriks.meter("api.request.restart_job").mark

        service = self.service(:reset_model, job_id: params[:id])
        if !service.accept?
          status 400
          result = false
        else
          Travis::Sidekiq::JobRestart.perform_async(id: params[:id], user_id: current_user.id)
          status 202
          result = true
        end
        respond_with(result: result, flash: service.messages)
      end

      get '/:job_id/log' do
        resource = service(:find_log, params).run
        if (resource && resource.removed_at) && accepts?('application/json')
          respond_with resource
        elsif (!resource || resource.archived?)
          # the way we use responders makes it hard to validate proper format
          # automatically here, so we need to check it explicitly
          if accepts?('text/plain')
            archived_log_path = archive_url("/jobs/#{params[:job_id]}/log.txt")

            if params[:cors_hax]
              status 204
              headers['Access-Control-Expose-Headers'] = 'Location'
              headers['Location'] = archived_log_path
            else
              redirect archived_log_path, 307
            end
          else
            status 406
          end
        else
          respond_with resource
        end
      end

      patch '/:id/log', scope: :private do |id|
        begin
          self.service(:remove_log, params).run
        rescue Travis::AuthorizationDenied => ade
          status 401
          { error: { message: ade.message } }
        rescue Travis::JobUnfinished, Travis::LogAlreadyRemoved => e
          status 409
          { error: { message: e.message } }
        rescue => e
          status 500
          { error: { message: "Unexpected error occurred: #{e.message}" } }
        end
      end

      get "/:job_id/annotations" do
        respond_with service(:find_annotations, params)
      end

      post "/:job_id/annotations" do
        if params[:status] && params[:description]
          annotation = service(:update_annotation, params).run

          status annotation ? 204 : 401
        else
          status 422

          { "error" => "Must include status and description" }
        end
      end

      def archive_url(path)
        "https://s3.amazonaws.com/#{hostname('archive')}#{path}"
      end

      def hostname(name)
        "#{name}#{'-staging' if Travis.env == 'staging'}.#{Travis.config.host.split('.')[-2, 2].join('.')}"
      end

      def debug_data
        {
          debug: {
            stage: 'before_install',
            previous_status: 'failed',
            created_by: current_user.login
          }
        }
      end
    end
  end
end

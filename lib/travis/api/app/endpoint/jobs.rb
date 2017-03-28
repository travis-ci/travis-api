require 'travis/api/app'
require 'travis/api/enqueue/services/restart_model'
require 'travis/api/enqueue/services/cancel_model'

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
        Metriks.meter("api.v2.request.cancel_job").mark

        service = Travis::Enqueue::Services::CancelModel.new(current_user, { job_id: params[:id] })

        if !service.authorized?
          json = { error: {
            message: "You don't have access to cancel job(#{params[:id]})"
          } }

          Metriks.meter("api.v2.request.cancel_job.unauthorized").mark
          status 403
          respond_with json
        elsif !service.can_cancel?
          json = { error: {
            message: "The job(#{params[:id]}) can't be canceled",
              code: 'cant_cancel'
          } }

          Metriks.meter("api.v2.request.cancel_job.cant_cancel").mark
          status 422
          respond_with json
        else
          payload = { id: params[:id], user_id: current_user.id, source: 'api' }
          service.push("job:cancel", payload)

          Metriks.meter("api.v2.request.cancel_job.success").mark
          status 204
        end
      end

      post '/:id/restart' do
        Metriks.meter("api.v2.request.restart_job").mark

        service = Travis::Enqueue::Services::RestartModel.new(current_user, { job_id: params[:id] })

        result = if !service.accept?
          status 400
          false
        else
          payload = {id: params[:id], user_id: current_user.id}
          service.push("job:restart", payload)
          status 202
          true
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
          if accepts?('text/plain') || request.user_agent.to_s.start_with?('Travis')
            archived_log_path = if resource.respond_to?(:archived_url)
                                  resource.archived_url
                                else
                                  archive_url("/jobs/#{params[:job_id]}/log.txt")
                                end

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
    end
  end
end

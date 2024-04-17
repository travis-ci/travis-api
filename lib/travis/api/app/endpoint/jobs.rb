require 'travis/api/app'
require 'travis/api/enqueue/services/restart_model'
require 'travis/api/enqueue/services/cancel_model'
require 'travis/api/app/responders/base'

class Travis::Api::App
  class Endpoint
    class Jobs < Endpoint
      include Helpers::Accept

      before { authenticate_by_mode! }

      get '/' do
        prefer_follower do
          respond_with service(:find_jobs, params), include_log_id: include_log_id?
        end
      end

      get '/:id' do
        job = service(:find_job, params).run
        if job && job.repository
          respond_with job, type: :job, include_log_id: include_log_id?
        else
          json = { error: { message: "The job(#{params[:id]}) couldn't be found" } }
          status 404
          respond_with json
        end
      end

      post '/:id/cancel' do
        Metriks.meter("api.v2.request.cancel_job").mark

        service = Travis::Enqueue::Services::CancelModel.new(current_user, { job_id: params[:id] })

        auth_for_repo(service&.target&.repository&.id, 'repository_build_cancel') unless Travis.config.legacy_roles

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
          payload = { id: params[:id], user_id: current_user.id, source: 'api', reason: "Job Cancelled manually by User with id: #{current_user.login}" }
          service.push("job:cancel", payload)

          Metriks.meter("api.v2.request.cancel_job.success").mark
          status 204
        end
      end

      post '/:id/restart' do
        Metriks.meter("api.v2.request.restart_job").mark

        service = Travis::Enqueue::Services::RestartModel.new(current_user, { job_id: params[:id] })

        auth_for_repo(service&.repository&.id, 'repository_build_restart') unless Travis.config.legacy_roles
        disallow_migrating!(service.repository)

        result = if !service.accept?
          status 400
          false
        else
          payload = {id: params[:id], user_id: current_user.id, restarted_by: current_user.id}
          service.push("job:restart", payload)
          status 202
          true
        end

        respond_with(result: result, flash: service.messages)
      end

      get '/:job_id/log', scope: [:public, :log] do
        resource = service(:find_log, job_id: params[:job_id]).run
        job = Job.find(params[:job_id])

        if (job.try(:private?) || !allow_public?) && !has_permission?(job)
          halt 404
        elsif resource.nil?
          status 200
          body empty_log(Integer(params[:job_id])).to_json
        elsif resource.removed_at && accepts?('application/json')
          attach_log_token if job.try(:private?)
          respond_with resource
        elsif resource.archived?
          # the way we use responders makes it hard to validate proper format
          # automatically here, so we need to check it explicitly
          if accepts?('text/plain')
            respond_with resource.archived_log_content
          elsif accepts?('application/json')
            attach_log_token if job.try(:private?)
            respond_with resource.as_json
          else
            status 406
          end
        else
          attach_log_token if job.try(:private?)
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

      def has_permission?(job)
        current_user && Permission.where(user: current_user, repository_id: job.repository_id).first
      end

      def attach_log_token
        headers['X-Log-Access-Token'] = log_token
        headers['Access-Control-Expose-Headers'] = "Location, Content-Type, Cache-Control, Expires, Etag, Last-Modified, X-Log-Access-Token, X-Request-ID"
      end

      def log_token
        attrs = {
          app_id: 1, user: current_user, expires_in: 1.day,
          extra: {
            required_params: { job_id: params['job_id'] }
          }
        }
        token = Travis::Api::App::AccessToken.new(attrs).tap(&:save)
        token.token
      end

      def archive_url(path)
        "https://s3.amazonaws.com/#{hostname('archive')}#{path}"
      end

      def hostname(name)
        "#{name}#{'-staging' if Travis.env == 'staging'}.#{Travis.config.host.split('.')[-2, 2].join('.')}"
      end

      private def include_log_id?
        params[:include_log_id] ||
          request.user_agent.to_s.start_with?('Travis')
      end

      private def empty_log(job_id)
        { log: { job_id: job_id, parts: [], :@type => 'Log' } }
      end
    end
  end
end

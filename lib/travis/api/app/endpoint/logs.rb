require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Logs < Endpoint
      before { authenticate_by_mode! }

      get '/:id' do |id|
        resource = service(:find_log, id: params[:id]).run
        job = resource ? Job.find(resource.job_id) : nil

        if !resource || ((job.try(:private?) || !allow_public?) && !has_permission?(job))
          halt 404
        elsif resource.removed_at && accepts?('application/json')
          respond_with resource
        elsif resource.archived?
          # the way we use responders makes it hard to validate proper format
          # automatically here, so we need to check it explicitly
          if accepts?('text/plain')
            redirect resource.archived_url, 307
          elsif accepts?('application/json')
            respond_with resource.as_json
          else
            status 406
          end
        else
          respond_with resource
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

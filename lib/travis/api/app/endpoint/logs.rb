require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Logs < Endpoint
      get '/:id' do |id|
        # NOTE: the body of this method is identical to:
        # [endpoint]/jobs/:job_id/log
        resource = service(:find_log, params).run
        if (resource && resource.removed_at) && accepts?('application/json')
          respond_with resource
        elsif (!resource || resource.archived?)
          # the way we use responders makes it hard to validate proper format
          # automatically here, so we need to check it explicitly
          if accepts?('text/plain')
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
    end
  end
end

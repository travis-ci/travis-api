require 'travis/api/app'

class Travis::Api::App
  # Namespace for helpers.
  module Helpers
    Backports.require_relative_dir 'helpers'

    def patch_log_for_job(id, params)
      result = self.service(:remove_log, params)
      respond_with result
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
end

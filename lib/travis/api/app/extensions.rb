require 'travis/api/app'

class Travis::Api::App
  # Namespace for Sinatra extensions.
  module Extensions
    Backports.require_relative_dir 'extensions'
  end
end

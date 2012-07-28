require 'travis/api/app'

class Travis::Api::App
  # Namespace for helpers.
  module Helpers
    Backports.require_relative_dir 'helpers'
  end
end

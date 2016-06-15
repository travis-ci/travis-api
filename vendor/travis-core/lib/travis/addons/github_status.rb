module Travis
  module Addons
    module GithubStatus
      require 'travis/addons/github_status/instruments'
      require 'travis/addons/github_status/event_handler'
      class Task < ::Travis::Task; end
    end
  end
end


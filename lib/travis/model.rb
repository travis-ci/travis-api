# This module is required for preloading classes on JRuby, see
#   https://github.com/travis-ci/travis-support/blob/master/lib/core_ext/module/load_constants.rb
# which is used in
#   https://github.com/travis-ci/travis-hub/blob/master/lib/travis/hub/cli.rb#L15
require 'active_record'
require 'core_ext/active_record/base'

module Travis
  class Model < ActiveRecord::Base
    self.abstract_class = true

    require 'travis/model/scope_access'
    require 'travis/model/account'
    require 'travis/model/branch'
    require 'travis/model/broadcast'
    require 'travis/model/build'
    require 'travis/model/build_backup'
    require 'travis/model/commit'
    require 'travis/model/email'
    require 'travis/model/env_helpers'
    require 'travis/model/job'
    require 'travis/model/membership'
    require 'travis/model/organization'
    require 'travis/model/owner_group'
    require 'travis/model/permission'
    require 'travis/model/pull_request'
    require 'travis/model/repository'
    require 'travis/model/request'
    require 'travis/model/ssl_key'
    require 'travis/model/subscription'
    require 'travis/model/token'
    require 'travis/model/user'
    require 'travis/model/url'


    cattr_accessor :follower_connection_handler

    class << self
      def connection_handler
        if Thread.current['Travis.with_follower_connection_handler']
          follower_connection_handler
        else
          super
        end
      end

      def establish_follower_connection(spec)
        self.follower_connection_handler = ActiveRecord::ConnectionAdapters::ConnectionHandler.new unless self.follower_connection_handler
        using_follower do
          self.establish_connection(spec)
        end
      end

      def using_follower
        Thread.current['Travis.with_follower_connection_handler'] = true
        yield
      ensure
        Thread.current['Travis.with_follower_connection_handler'] = false
      end
    end
  end
end

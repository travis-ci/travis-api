require 'active_record'
require 'active_record_postgres_variables'
require 'travis/support/database'

module Travis::Setup
  module DatabaseConnections
    extend self

    def setup
      setup_main_database
      setup_logs_database
    end

    def setup_main_database
      Travis.config.database.variables                  ||= {}
      Travis.config.database.variables.application_name ||= ["api", Travis.env, ENV['DYNO']].compact.join(?-)
      Travis::Database.connect
    end

    def setup_logs_database
      return unless Travis.config.logs_database
      pool_size                          = ENV['DATABASE_POOL_SIZE']
      Travis.config.logs_database[:pool] = pool_size.to_i if pool_size
    end
  end
end

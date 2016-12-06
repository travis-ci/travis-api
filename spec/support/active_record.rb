require 'active_record'
require 'logger'
require 'fileutils'
require 'database_cleaner'
require 'travis/testing/factories'

FileUtils.mkdir_p('log')

# TODO why not make this use Travis::Database.connect ?
config = Travis.config.database.to_h
logs_config = Travis.config.logs_database.to_h

ActiveRecord::Base.default_timezone = :utc
ActiveRecord::Base.logger = Logger.new('log/test.db.log')
Travis::LogsModel.establish_connection(logs_config)
ActiveRecord::Base.establish_connection(config)

DatabaseCleaner.clean_with :truncation
DatabaseCleaner.strategy = :transaction

module Support
  module ActiveRecord
    extend ActiveSupport::Concern

    included do
      before :suite do
        DatabaseCleaner.clean_with(:truncation)
      end

      before :each do
        DatabaseCleaner.strategy = :transaction
      end

      before(:each, :truncation => true) do
        DatabaseCleaner.strategy = :truncation
      end

      before :each do
        DatabaseCleaner.start
      end

      after :each do
        DatabaseCleaner.clean
      end
    end
  end
end

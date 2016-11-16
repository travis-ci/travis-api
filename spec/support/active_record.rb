require 'active_record'
require 'logger'
require 'fileutils'
require 'database_cleaner'
require 'travis/testing/factories'

FileUtils.mkdir_p('log')

# TODO why not make this use Travis::Database.connect ?
config = Travis.config.database.to_h
config.merge!('adapter' => 'jdbcpostgresql', 'username' => ENV['USER']) if RUBY_PLATFORM == 'java'

logs_config = config.clone.merge(:database => "travis_logs_#{Travis.env}")

ActiveRecord::Base.default_timezone = :utc
ActiveRecord::Base.logger = Logger.new('log/test.db.log')
ActiveRecord::Base.configurations = {
  'test' => config,
  'logs_test' => logs_config,
}

Travis::LogsModel.establish_connection('logs_test')
ActiveRecord::Base.establish_connection('test')

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

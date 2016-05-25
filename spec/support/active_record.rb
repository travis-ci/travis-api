require 'active_record'
require 'logger'
require 'fileutils'
require 'travis/testing/factories'

FileUtils.mkdir_p('log')

# TODO why not make this use Travis::Database.connect ?
config = Travis.config.database.to_h
config.merge!('adapter' => 'jdbcpostgresql', 'username' => ENV['USER']) if RUBY_PLATFORM == 'java'

ActiveRecord::Base.default_timezone = :utc
ActiveRecord::Base.logger = Logger.new('log/test.db.log')
ActiveRecord::Base.configurations = { 'test' => config }
ActiveRecord::Base.establish_connection('test')

DatabaseCleaner.clean_with :truncation

module Support
  module ActiveRecord
    extend ActiveSupport::Concern

    included do
      before :each, truncation: true do
        DatabaseCleaner.clean
        DatabaseCleaner.strategy = :truncation
      end
    end
  end
end

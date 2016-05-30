require 'travis'
require 'rails/engine'

module Travis
  class Engine < Rails::Engine
    initializer 'add migrations path' do |app|
      # need to insert to both Rails.app.paths and Migrator.migration_paths
      # because Rails' stupid rake tasks copy them over before loading the
      # engines *unless* multiple rake db tasks are combined (as in rake
      # db:create db:migrate). Happens in Rails <= 3.2.2
      paths = [
        Rails.application.paths['db/migrate'],
        ActiveRecord::Migrator.migrations_paths
      ]
      paths.each do |paths|
        path = root.join('db/migrate').to_s
        paths << path unless paths.include?(path)
      end
    end
  end
end

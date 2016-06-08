Rails.application.paths["db/migrate"] = ["#{Gem.loaded_specs['travis-pro-migrations'].full_gem_path}/db/migrate", "#{Gem.loaded_specs['travis-migrations'].full_gem_path}/db/migrate"]

ActiveRecord::Base.schema_format = :sql

task('db:structure:load' => :copy_structure)

task(:copy_structure) do
  require 'fileutils'
  structure = "#{Gem.loaded_specs['travis-pro-migrations'].full_gem_path}/db/structure.sql"
  FileUtils.mkdir_p('db')
  FileUtils.cp(structure, 'db/structure.sql')
end
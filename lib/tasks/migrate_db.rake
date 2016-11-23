ActiveRecord::Base.schema_format = :sql

task('db:structure:load' => :copy_structure)

task(:copy_structure) do
  require 'fileutils'
  structure = "#{Gem.loaded_specs['travis-migrations'].full_gem_path}/db/main/structure.sql"
  FileUtils.mkdir_p('db')
  FileUtils.cp(structure, 'db/structure.sql')
end

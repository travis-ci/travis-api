# Populate :migrating_status with data from :migrating
# after this column has been added to orgs, users, and repos
desc "Populate migrating_status for orgs, users, repos"
task :populate_migrating_status do
  require "travis"
  require "travis/api/v3"
  Travis::Database.connect

  puts "Going to migrate status of #{repos.count} repos"
  repos = Travis::API::V3::Models::Repository.where.not(migrated_at: nil)
  repos.update_all(:migrating_status, :migrated)

  puts "Going to migrate status of #{repos.count} users"
  users = Travis::API::V3::Models::User.where.not(migrated_at: nil)
  users.update_all(:migrating_status, :migrated)

  puts "Going to migrate status of #{repos.count} orgs"
  orgs = Travis::API::V3::Models::Organization.where.not(migrated_at: nil)
  orgs.update_all(:migrating_status, :migrated)
end

task default: :populate_migrating_status


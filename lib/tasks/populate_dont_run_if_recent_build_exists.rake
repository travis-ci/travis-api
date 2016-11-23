# Populate :dont_run_if_recent_build_exists in Crons table
# after the column has been added
desc "Populate dont_run_if_recent_build_exists for all cron jobs"
task :populate_dont_run_if_recent_build_exists do
  require "travis"
  require "travis/api/v3"
  Travis::Database.connect

  Travis::API::V3::Models::Cron.all.each do |cron|
    cron.update_attribute(:dont_run_if_recent_build_exists, cron.disable_by_build)
  end
end

task default: :populate_dont_run_if_recent_build_exists

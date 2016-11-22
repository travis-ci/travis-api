# Populate :next_run and :last_run in Crons table
# after these columns have been added
desc "Populate next and last runs for all cron jobs"
task :populate_next_last_cron_runs do
  require "travis"
  require "travis/api/v3"
  Travis::Database.connect

  Travis::API::V3::Models::Cron.all.each do |cron|
    cron.update_attribute(:last_run, last_cron_build_date(cron))
    cron.schedule_next_build(from: cron.last_run || cron.created_at)
  end
end

task default: :populate_next_last_cron_runs

def last_cron_build_date(cron)
  last_cron_build = Travis::API::V3::Models::Build.where(
      repository_id: cron.branch.repository.id,
      branch:        cron.branch.name,
      event_type:    "cron"
  ).order("id DESC").first
  return last_cron_build.created_at unless last_cron_build.nil?
  nil
end

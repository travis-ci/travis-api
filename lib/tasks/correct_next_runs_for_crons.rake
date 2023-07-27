$: << 'lib'
# Reset :next_run for crons, so that they run  according to the
# time they were created and the chosen intervals
# This task can help mitigate issues like
# https://github.com/travis-pro/team-teal/issues/2602

require "date"

desc "Correct next_run for all cron jobs"
TODAY = Date.today

task :correct_next_runs_for_crons do
  require "travis"
  require "travis/api/v3"
  Travis::Database.connect
  puts "Total number of crons: #{Travis::API::V3::Models::Cron.count}"

  ["daily", "weekly", "monthly"].each do |interval|
    crons = crons_with_interval(interval)
    crons.all.each do |cron|
      corrected = send("corrected_#{interval}_next_run", cron)
      puts "#{interval} cron #{cron.id}. Set next_run to #{corrected}"
      cron.update!(next_run: corrected)
    end
  end
end

task default: :correct_next_runs_for_crons

def crons_with_interval(interval)
  Travis::API::V3::Models::Cron.where(interval: interval)
end

def corrected_daily_next_run(cron)
  corrected = base_corrected(cron.created_at)
  corrected += 1.day if corrected < DateTime.now
  return corrected
end

def corrected_weekly_next_run(cron)
  corrected = base_corrected(cron.created_at, weekday(cron.created_at.wday))
  corrected += 1.week if corrected < DateTime.now
  return corrected
end

def corrected_monthly_next_run(cron)
  corrected = base_corrected(cron.created_at, cron.created_at.day)
  corrected += 1.month if corrected < DateTime.now
  return corrected
end

def weekday(wday)
  TODAY.day + wday - TODAY.wday
end

def base_corrected(created_at, day=TODAY.day)
  DateTime.new(
    TODAY.year,
    TODAY.month,
    day,
    created_at.hour,
    created_at.min,
    created_at.sec,
    created_at.zone
  )
end

def last_cron_build_date(cron)
  last_cron_build = Travis::API::V3::Models::Build.where(
      repository_id: cron.branch.repository.id,
      branch:        cron.branch.name,
      event_type:    "cron"
  ).order("id DESC").first
  return last_cron_build.created_at unless last_cron_build.nil?
  nil
end

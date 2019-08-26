$: << 'lib'
# Command to run this task:
# bundle exec rake merge:enable_allow_migration[10,true]
# where you want 10 BetMigrationRequests to be processed,
# and you want debug output to be printed
require "redis"
require "travis"
require "travis/api/v3"

namespace :merge do
  desc "Enable repo migration for users and orgs"
  task :enable_allow_migration, :num_requests, :debug do |task, args|
    args.with_defaults(num_requests: 50, debug: false)
    Travis::Database.connect

    requests = Travis::API::V3::Models::BetaMigrationRequest.where(accepted_at: nil).limit(args[:num_requests])

    puts "About to enable :allow_migration for #{requests.count} opted-in users and the organizations they selected."

    requests.each do |request|
       ActiveRecord::Base.transaction do
        (request.organizations + [request.owner]).each do |owner|
          Travis::Features.activate_owner(:allow_migration, owner)
        end

        send_email_confirmation(request.owner)

        request.update(accepted_at: DateTime.now)
        puts "[Request ID: #{request.id}] Feature activated for Owner: #{request.owner_id} and orgs: #{request.organizations.pluck(:id)}" if args[:debug]
      end
    end
  end
end

def send_email_confirmation(user)
  @mailer ||= Travis::API::V3::Models::Mailer.new
  @mailer.send_beta_confirmation(user)
end

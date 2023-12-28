# Skip the CI/CD form for organization users
desc "skip ci/cd form for organization users"
task :skip_ci_cd_form do
  require "travis"
  require "travis/api/v3"
  Travis::Database.connect

  org_logins = %w[celigo gametimesf ClassifyVenture mapbox choosemylo vidahealth]
  organizations = Travis::API::V3::Models::Organization.where(login: org_logins)

  # # loop through each org, get their users and update each user's billing_wizard_state to 4
  organizations.each do |org|
    org.users.each do |user|
      puts "Updating user #{user.id} with billing_wizard_state 4"
      Travis::API::V3::Queries::Storage.new({'id' => :billing_wizard_state, 'user.id' => user.id, 'value' => 4}, 'Storage').update
    end
  end
end

task default: :skip_ci_cd_form

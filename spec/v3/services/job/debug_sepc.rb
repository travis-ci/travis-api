require 'spec_helper'

describe Travis::API::V3::Services::Job::Debug do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:owner_type)  { repo.owner_type.constantize }
  let(:owner)       { owner_type.find(repo.owner_id)}
  let(:build)       { repo.builds.last }
  let(:jobs)        { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:job)         { jobs.last }

  before { repo.requests.each(&:delete) }

  before do
    Travis::Features.stubs(:owner_active?).returns(true)
    @original_sidekiq = Sidekiq::Client
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = []

    Travis.config.stubs(:debug_tools_enabled).returns true
  end

  after do
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = @original_sidekiq
  end

  describe "#run" do
    context "when unauthenticated" do
      before  { post("/v3/job/#{job.id}/debug")      }
      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "login_required",
        "error_message" => "login required"
      }}
    end

    context "when authenticated" do
      let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
      let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}

      context "without sufficient authorization" do
        before { post("/v3/job/#{job.id}/debug", {}, headers) }

        example { expect(last_response.status).to be == 403 }
        example { expect(JSON.load(body)).to include(
          "@type"         => "error",
          "error_type"    => "insufficient_access",
          "error_message" => "operation requires debug access to job",
          "resource_type" => "job",
        )}
      end

      context "with sufficient authorization" do
        let(:params) {{}}

        before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
        before { post("/v3/job/#{job.id}/debug", {}, headers) }

        example { expect(last_response.status).to be == 202 }

        example { expect(job.reload.debug_options).to include(
          stage: "before_install",
          created_by: owner.login,
          quiet: false
        ) }
      end
    end
  end
end
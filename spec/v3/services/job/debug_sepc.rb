require 'spec_helper'

describe Travis::API::V3::Services::Job::Debug do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:sidekiq_payload) { JSON.load(Sidekiq::Client.last['args'].last[:payload]).deep_symbolize_keys }
  let(:sidekiq_params) { Sidekiq::Client.last['args'].last.deep_symbolize_keys }
  before { repo.requests.each(&:delete) }

  before do
    Travis::Features.stubs(:owner_active?).returns(true)
    @original_sidekiq = Sidekiq::Client
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = []
  end

  after do
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = @original_sidekiq
  end

  describe "not authenticated" do
    before  { post("/v3/job/#{job.id}/debug")      }
    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    }}
  end

end
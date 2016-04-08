require 'spec_helper'

describe Travis::API::V3::Services::Tmate::Event do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:owner_type)  { repo.owner_type.constantize }
  let(:owner)       { owner_type.find(repo.owner_id)}
  let(:build)       { repo.builds.last }
  let(:jobs)        { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:job)         { jobs.last }

  let(:session_token) do
    token = Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1)
    headers = { 'HTTP_AUTHORIZATION' => "token #{token}" }
    Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true)
    post("/v3/job/#{job.id}/debug", {}, headers)
    token = job.reload.debug_options[:session_token]
    "#{job.id}/#{token}"
  end
  let(:session_id) { SecureRandom.uuid }
  let(:event_common) { { userdata: session_token, session_id: session_id } }

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
    context "when receiving an event with a malformed job token" do
      before  { post("/v3/tmate/event", FactoryGirl.build(:event_session_open, userdata: 'xxx')) }
      example { expect(last_response.status).to be == 400 }
      example { expect(JSON.load(body)).to include("@type" => "error", "error_type" => "wrong_params") }
    end

    context "when receiving an event with an invalid job id" do
      before  { post("/v3/tmate/event", FactoryGirl.build(:event_session_open, userdata: "1234/abc")) }
      example { expect(last_response.status).to be == 404 }
      example { expect(JSON.load(body)).to include("@type" => "error", "error_type" => "not_found") }
    end

    context "when receiving an event with an invalid debug token" do
      before  { post("/v3/tmate/event", FactoryGirl.build(:event_session_open, userdata: "#{job.id}/abc")) }
      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to include("@type" => "error", "error_type" => "wrong_credentials") }
    end

    context "when no event has been received yet" do
      example { session_token; expect(job.reload.debug_options).to include(
        session_state: "pending",
        session_data: {}
      )}
    end

    context "when receiving a session_open" do
      let(:event_session_open) { FactoryGirl.build(:event_session_open, **event_common) }
      before { post("/v3/tmate/event", event_session_open) }

      example { expect(last_response.status).to be == 202 }
      example { expect(job.reload.debug_options).to include(
        session_state: "opened",
        session_data: {
          stoken:      event_session_open["params"]["stoken"],
          stoken_ro:   event_session_open["params"]["stoken_ro"],
          ssh_cmd_fmt: event_session_open["params"]["ssh_cmd_fmt"],
      })}
    end

    context "when receiving a session_open twice (e.g. due to reconnection)" do
      let(:event_session_open1) { FactoryGirl.build(:event_session_open, **event_common) }
      let(:event_session_open2) { FactoryGirl.build(:event_session_open, **event_common, reconnected: true) }
      before { post("/v3/tmate/event", event_session_open1) }
      before { post("/v3/tmate/event", event_session_open2) }

      example { expect(last_response.status).to be == 202 }
      example { expect(job.reload.debug_options).to include(
        session_state: "opened",
        session_data: {
          stoken:      event_session_open2["params"]["stoken"],
          stoken_ro:   event_session_open2["params"]["stoken_ro"],
          ssh_cmd_fmt: event_session_open2["params"]["ssh_cmd_fmt"],
      })}
    end

    context "when receiving a session_close" do
      let(:event_session_open)  { FactoryGirl.build(:event_session_open,  **event_common) }
      let(:event_session_close) { FactoryGirl.build(:event_session_close, **event_common) }
      before { post("/v3/tmate/event", event_session_open) }
      before { post("/v3/tmate/event", event_session_close) }

      example { expect(job.reload.debug_options).to include(
        session_state: "closed",
        session_data: {}
      )}
    end
  end
end

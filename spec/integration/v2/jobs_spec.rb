describe 'Jobs', set_app: true do
  let!(:jobs) {[
    FactoryGirl.create(:test, :number => '3.1', :queue => 'builds.common'),
    FactoryGirl.create(:test, :number => '3.2', :queue => 'builds.common')
  ]}
  let(:job) { jobs.first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  it '/jobs?queue=builds.common' do
    response = get '/jobs', { queue: 'builds.common' }, headers
    response.should deliver_json_for(Job.queued('builds.common'), version: 'v2')
  end

  it '/jobs/:id' do
    response = get "/jobs/#{job.id}", {}, headers
    response.status.should == 200
    expected = Travis::Api::Serialize.data(job, version: 'v2')
    expected.delete('log_id')
    parsed = MultiJson.decode(response.body)
    parsed['job'].delete('log_id')
    parsed.should == expected
  end

  context 'GET /jobs/:job_id/log.txt' do
    it 'returns log for a job' do
      stub_request(:get, "#{Travis.config.logs_api.url}/logs/#{job.id}?by=job_id")
        .to_return(status: 200, body: JSON.dump(content: 'the log'))
      response = get("/jobs/#{job.id}/log.txt", {}, headers)
      expect(response).to deliver_as_txt('the log', version: 'v2')
    end

    context 'when log is archived' do
      it 'redirects to archive' do
        Travis::RemoteLog.expects(:fetch_archived_url)
          .returns("https://s3.amazonaws.com/archive.travis-ci.org/jobs/#{job.id}/log.txt")
        stub_request(:get, "#{Travis.config.logs_api.url}/logs/#{job.id}?by=job_id")
          .to_return(
            status: 200,
            body: JSON.dump(
              content: 'the log',
              archived_at: Time.now,
              archive_verified: true
            )
          )
        response = get(
          "/jobs/#{job.id}/log.txt",
          {},
          { 'HTTP_ACCEPT' => 'text/plain; version=2' }
        )
        expect(response).to redirect_to(
          "https://s3.amazonaws.com/archive.travis-ci.org/jobs/#{job.id}/log.txt"
        )
      end
    end

    context 'when log is missing' do
      it 'responds with an empty representation' do
        stub_request(:get, "#{Travis.config.logs_api.url}/logs/#{job.id}?by=job_id")
          .to_return(status: 404, body: '')
        response = get(
          "/jobs/#{job.id}/log.txt",
          {},
          { 'HTTP_ACCEPT' => 'text/plain; version=2' }
        )
        response.status.should == 200
        JSON.parse(response.body, symbolize_names: true).should eq(
          { log: { job_id: job.id, parts: [], :@type => 'Log' } }
        )
      end
    end

    context 'with cors_hax param' do
      it 'renders No Content response with location of the archived log' do
        stub_request(:get, "#{Travis.config.logs_api.url}/logs/#{job.id}?by=job_id")
          .to_return(
            status: 200,
            body: JSON.dump(
              content: nil,
              aggregated_at: Time.now,
              archived_at: Time.now,
              archive_verified: true
            )
          )
        Travis::RemoteLog.any_instance.stubs(:archived_url).returns(
          "https://s3.amazonaws.com/archive.travis-ci.org/jobs/#{job.id}/log.txt"
        )
        response = get(
          "/jobs/#{job.id}/log.txt?cors_hax=true",
          {},
          { 'HTTP_ACCEPT' => 'text/plain; version=2' }
        )
        expect(response.status).to eq 204
        expect(response.headers['Location']).to eq(
          "https://s3.amazonaws.com/archive.travis-ci.org/jobs/#{job.id}/log.txt"
        )
      end
    end

    context 'with chunked log requested' do
      it 'always responds with 406' do
        stub_request(:get, "#{Travis.config.logs_api.url}/logs/#{job.id}?by=job_id")
          .to_return(
            status: 200,
            body: JSON.dump(
              content: 'fla flah flooh',
              aggregated_at: Time.now,
              archived_at: Time.now,
              archive_verified: true
            )
          )
        response = get(
          "/jobs/#{job.id}/log",
          {},
          { 'HTTP_ACCEPT' => 'application/json; version=2; chunked=true' }
        )
        expect(response.status).to eq(406)
      end
    end
  end

  describe 'PATCH /jobs/:job_id/log' do
    let(:user) { User.where(login: 'svenfuchs').first }
    let(:token) do
      Travis::Api::App::AccessToken.create(user: user, app_id: -1)
    end

    before :each do
      headers.merge! 'HTTP_AUTHORIZATION' => "token #{token}"
    end

    context 'when user does not have push permissions' do
      before :each do
        user.permissions.create!(
          repository_id: job.repository.id,
          push: false
        )
      end

      it 'returns status 401' do
        stub_request(
          :get,
          "#{Travis.config.logs_api.url}/logs/#{job.id}?by=job_id"
        ).to_return(status: 200, body: JSON.dump(content: 'flah'))
        response = patch(
          "/jobs/#{job.id}/log",
          { reason: 'Because reason!' },
          headers
        )
        expect(response.status).to eq 401
      end
    end

    context 'when user has push permission' do
      context 'when job is not finished' do
        before :each do
          job.stubs(:finished?).returns false
          user.permissions.create!(
            repository_id: job.repository.id, push: true
          )
        end

        it 'returns status 409' do
          stub_request(
            :get,
            "#{Travis.config.logs_api.url}/logs/#{job.id}?by=job_id"
          ).to_return(
            status: 200,
            body: JSON.dump(content: 'flah', job_id: job.id)
          )
          response = patch(
            "/jobs/#{job.id}/log", { reason: 'Because reason!' }, headers
          )
          expect(response.status).to eq 409
        end
      end

      context 'when job is finished' do
        let(:finished_job) { Factory(:test, state: 'passed') }

        before :each do
          user.permissions.create!(
            repository_id: finished_job.repository.id, push: true
          )
        end

        it 'returns status 200' do
          stub_request(
            :get,
            "#{Travis.config.logs_api.url}/logs/#{finished_job.id}?by=job_id"
          ).to_return(
            status: 200,
            body: JSON.dump(content: 'flah', job_id: finished_job.id)
          )
          stub_request(
            :put,
            "#{Travis.config.logs_api.url}/logs/#{finished_job.id}?removed_by=#{user.id}"
          ).to_return(
            status: 200,
            body: JSON.dump(content: '', job_id: finished_job.id)
          )
          response = patch(
            "/jobs/#{finished_job.id}/log",
            { reason: 'Because reason!' },
            headers
          )
          expect(response.status).to eq 200
        end
      end
    end
  end

  it "GET /jobs/:id/annotations" do
    annotation_provider = Factory(:annotation_provider)
    annotation = annotation_provider.annotations.create(job_id: job.id, status: "passed", description: "Foobar")
    response = get "/jobs/#{job.id}/annotations", {}, headers
    response.should deliver_json_for(Annotation.where(id: annotation.id), version: 'v2')
  end

  describe "POST /jobs/:id/annotations" do
    context "with valid credentials" do
      it "responds with a 204" do
        Travis::Services::UpdateAnnotation.any_instance.stubs(:annotations_enabled?).returns(true)

        annotation_provider = Factory(:annotation_provider)
        response = post "/jobs/#{job.id}/annotations", { username: annotation_provider.api_username, key: annotation_provider.api_key, status: "passed", description: "Foobar" }, headers
        response.status.should eq(204)
      end
    end

    context "without a description" do
      it "responds with a 422" do
        annotation_provider = Factory(:annotation_provider)
        response = post "/jobs/#{job.id}/annotations", { username: annotation_provider.api_username, key: annotation_provider.api_key, status: "errored" }, headers
        response.status.should eq(422)
      end
    end

    context "without a status" do
      it "responds with a 422" do
        annotation_provider = Factory(:annotation_provider)
        response = post "/jobs/#{job.id}/annotations", { username: annotation_provider.api_username, key: annotation_provider.api_key, description: "Foobar" }, headers
        response.status.should eq(422)
      end
    end

    context "with invalid credentials" do
      it "responds with a 401" do
        response = post "/jobs/#{job.id}/annotations", { username: "invalid-username", key: "invalid-key", status: "passed", description: "Foobar" }, headers
        response.status.should eq(401)
      end
    end
  end

  describe 'POST /jobs/:id/cancel' do
    let(:user)    { User.where(login: 'svenfuchs').first }
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }

    before {
      headers.merge! 'HTTP_AUTHORIZATION' => "token #{token}"
      user.permissions.create!(repository_id: job.repository.id, :push => true, :pull => true)
    }

    context 'when user does not have rights to cancel the job' do
      before { user.permissions.destroy_all }

      it 'responds with 403' do
        response = post "/jobs/#{job.id}/cancel", {}, headers
        response.status.should == 403
      end

      context 'and tries to enqueue cancel event for the Hub' do
        before { Travis::Features.activate_owner(:enqueue_to_hub, job.repository.owner) }

        it 'responds with 403' do
          response = post "/jobs/#{job.id}/cancel", {}, headers
          response.status.should == 403
        end
      end
    end

    context 'when job is not cancelable' do
      before { job.update_attribute(:state, 'passed') }

      it 'responds with 422' do
        response = post "/jobs/#{job.id}/cancel", {}, headers
        response.status.should == 422
      end

      context 'and tries to enqueue cancel event for the Hub' do
        before { Travis::Features.activate_owner(:enqueue_to_hub, job.repository.owner) }

        it 'responds with 422' do
          response = post "/jobs/#{job.id}/cancel", {}, headers
          response.status.should == 422
        end
      end
    end

    context 'when job can be canceled' do
      before do
        job.update_attribute(:state, 'created')
      end

      context 'and enqueues cancel event for the Hub' do
        before { Travis::Features.activate_owner(:enqueue_to_hub, job.repository.owner) }

        it 'cancels the job' do
          ::Sidekiq::Client.expects(:push)
          post "/jobs/#{job.id}/cancel", {}, headers
        end

        it 'responds with 204' do
          ::Sidekiq::Client.expects(:push)
          response = post "/jobs/#{job.id}/cancel", {}, headers
          response.status.should == 204
        end
      end
    end
  end

  describe 'POST /jobs/:id/restart' do
    let(:user)    { User.where(login: 'svenfuchs').first }
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }

    before {
      headers.merge! 'HTTP_AUTHORIZATION' => "token #{token}"
      user.permissions.create!(repository_id: job.repository.id, :pull => true, :push => true)
    }

    context 'when restart is not acceptable' do
      before { user.permissions.destroy_all }

      it 'responds with 400' do
        response = post "/jobs/#{job.id}/restart", {}, headers
        response.status.should == 400
      end

      context 'when enqueueing for the Hub' do
        before { Travis::Features.activate_owner(:enqueue_to_hub, job.repository.owner) }

        it 'responds with 400' do
          response = post "/jobs/#{job.id}/restart", {}, headers
          response.status.should == 400
        end
      end
    end

    context 'when job passed' do
      before { job.update_attribute(:state, 'passed') }

      context 'Enqueues restart event for the Hub' do
        before { Travis::Features.activate_owner(:enqueue_to_hub, job.repository.owner) }

        it 'restarts the job' do
          ::Sidekiq::Client.expects(:push)
          response = post "/jobs/#{job.id}/restart", {}, headers
          response.status.should == 202
        end
        it 'sends the correct response body' do
          ::Sidekiq::Client.expects(:push)
          response = post "/jobs/#{job.id}/restart", {}, headers
          body = JSON.parse(response.body)
          body.should == {"result"=>true, "flash"=>[{"notice"=>"The job was successfully restarted."}]}
        end

      end
    end
  end
end

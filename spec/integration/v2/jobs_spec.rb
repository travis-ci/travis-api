require 'spec_helper'

describe 'Jobs' do
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
    response.should deliver_json_for(job, version: 'v2')
  end

  context 'GET /jobs/:job_id/log.txt' do
    it 'returns log for a job' do
      job.log.update_attributes!(content: 'the log')
      response = get "/jobs/#{job.id}/log.txt", {}, headers
      response.should deliver_as_txt('the log', version: 'v2')
    end

    context 'when log is archived' do
      it 'redirects to archive' do
        job.log.update_attributes!(content: 'the log', archived_at: Time.now, archive_verified: true)
        headers = { 'HTTP_ACCEPT' => 'text/plain; version=2' }
        response = get "/jobs/#{job.id}/log.txt", {}, headers
        response.should redirect_to("https://s3.amazonaws.com/archive.travis-ci.org/jobs/#{job.id}/log.txt")
      end
    end

    context 'when log is missing' do
      it 'redirects to archive' do
        job.log.destroy
        headers = { 'HTTP_ACCEPT' => 'text/plain; version=2' }
        response = get "/jobs/#{job.id}/log.txt", {}, headers
        response.should redirect_to("https://s3.amazonaws.com/archive.travis-ci.org/jobs/#{job.id}/log.txt")
      end
    end

    context 'with cors_hax param' do
      it 'renders No Content response with location of the archived log' do
        job.log.destroy
        headers = { 'HTTP_ACCEPT' => 'text/plain; version=2' }
        response = get "/jobs/#{job.id}/log.txt?cors_hax=true", {}, headers
        response.status.should == 204
        response.headers['Location'].should == "https://s3.amazonaws.com/archive.travis-ci.org/jobs/#{job.id}/log.txt"
      end
    end

    context 'with chunked log requested' do
      it 'responds with only selected chunks if after is specified' do
        job.log.parts << Log::Part.new(content: 'foo', number: 1, final: false)
        job.log.parts << Log::Part.new(content: 'bar', number: 2, final: true)
        job.log.parts << Log::Part.new(content: 'bar', number: 3, final: true)

        headers = { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json; chunked=true' }
        response = get "/jobs/#{job.id}/log", { after: 1 }, headers
        body = JSON.parse(response.body)

        body['log']['parts'].map { |p| p['number'] }.sort.should == [2, 3]
      end

      it 'responds with only selected chunks if part_numbers are requested' do
        job.log.parts << Log::Part.new(content: 'foo', number: 1, final: false)
        job.log.parts << Log::Part.new(content: 'bar', number: 2, final: true)
        job.log.parts << Log::Part.new(content: 'bar', number: 3, final: true)

        headers = { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json; chunked=true' }
        response = get "/jobs/#{job.id}/log", { part_numbers: '1,3,4' }, headers
        body = JSON.parse(response.body)

        body['log']['parts'].map { |p| p['number'] }.sort.should == [1, 3]
      end

      it 'responds with 406 when log is already aggregated' do
        job.log.update_attributes(aggregated_at: Time.now, archived_at: Time.now, archive_verified: true)
        job.log.should be_archived

        headers = { 'HTTP_ACCEPT' => 'application/json; version=2; chunked=true' }
        response = get "/jobs/#{job.id}/log", {}, headers
        response.status.should == 406
      end

      it 'responds with chunks instead of full log' do
        job.log.parts << Log::Part.new(content: 'foo', number: 1, final: false)
        job.log.parts << Log::Part.new(content: 'bar', number: 2, final: true)

        headers = { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json; chunked=true' }
        response = get "/jobs/#{job.id}/log", {}, headers
        response.should deliver_json_for(job.log, version: 'v2', params: { chunked: true})
      end

      it 'responds with full log if chunks are not available and full log is accepted' do
        job.log.update_attributes(aggregated_at: Time.now)
        headers = { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json; chunked=true, application/vnd.travis-ci.2+json' }
        response = get "/jobs/#{job.id}/log", {}, headers
        response.should deliver_json_for(job.log, version: 'v2')
      end
    end

    it 'adds removed info if the log is removed' do
      time = Time.utc(2015, 1, 9, 12, 57, 31)
      job.log.update_attributes(removed_at: time, removed_by: User.first)
      headers = { 'HTTP_ACCEPT' => 'application/json; chunked=true; version=2' }
      response = get "/jobs/#{job.id}/log", {}, headers
      body = JSON.parse(response.body)

      body['log']['removed_by'].should == 'Sven Fuchs'
      body['log']['removed_at'].should == "2015-01-09T12:57:31Z"
      body['log']['id'].should == job.log.id

      # make sure we return parts as chunked=true
      body['log']['parts'].length.should == 1
    end
  end

  describe 'PATCH /jobs/:job_id/log' do
    let(:user)    { User.where(login: 'svenfuchs').first }
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }

    before :each do
      headers.merge! 'HTTP_AUTHORIZATION' => "token #{token}"
    end

    context 'when user does not have push permissions' do
      before :each do
        user.permissions.create!(repository_id: job.repository.id, :push => false)
      end

      it 'returns status 401' do
        response = patch "/jobs/#{job.id}/log", { reason: 'Because reason!' }, headers
        response.status.should == 401
      end
    end

    context 'when user has push permission' do
      context 'when job is not finished' do
        before :each do
          job.stubs(:finished?).returns false
          user.permissions.create!(repository_id: job.repository.id, :push => true)
        end

        it 'returns status 409' do
          response = patch "/jobs/#{job.id}/log", { reason: 'Because reason!' }, headers
          response.status.should == 409
        end
      end

      context 'when job is finished' do
        let(:finished_job) { Factory(:test, state: 'passed') }

        before :each do
          user.permissions.create!(repository_id: finished_job.repository.id, :push => true)
        end

        it 'returns status 200' do
          response = patch "/jobs/#{finished_job.id}/log", { reason: 'Because reason!' }, headers
          response.status.should == 200
        end

      end
    end

    context 'when job is not found' do
      # TODO
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

      it 'cancels the job' do
        Travis::Sidekiq::JobCancellation.expects(:perform_async).with( id: job.id.to_s, user_id: user.id, source: 'api')
        post "/jobs/#{job.id}/cancel", {}, headers
      end

      it 'responds with 204' do
        response = post "/jobs/#{job.id}/cancel", {}, headers
        response.status.should == 204
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

      context 'Restart from travis-core' do
        before { Travis::Sidekiq::JobCancellation.stubs(:perform_async) }

        it 'restarts the job' do
          Travis::Sidekiq::JobRestart.expects(:perform_async).with(id: job.id.to_s, user_id: user.id)
          response = post "/jobs/#{job.id}/restart", {}, headers
          response.status.should == 202
        end
        it 'sends the correct response body' do
          Travis::Sidekiq::JobRestart.expects(:perform_async).with(id: job.id.to_s, user_id: user.id)
          response = post "/jobs/#{job.id}/restart", {}, headers
          body = JSON.parse(response.body)
          body.should == {"result"=>true, "flash"=>[{"notice"=>"The job was successfully restarted."}]}
        end
      end

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

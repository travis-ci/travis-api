describe Travis::Api::App::Endpoint::Logs, set_app: true do
  after { Travis.config.public_mode = false }

  context do
    let(:user) { FactoryBot.create(:user, login: :rkh) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:private_repo)   { FactoryBot.create(:repository, private: true) }
    let(:public_repo)    { FactoryBot.create(:repository, private: false) }
    let!(:private_build) { FactoryBot.create(:build, repository: private_repo, private: true) }
    let!(:public_build)  { FactoryBot.create(:build, repository: public_repo, private: false) }
    let(:public_migrated_repo) { FactoryBot.create(:repository, private: false, migrated_at: 1.day.ago) }
    let(:public_migrated_build) { FactoryBot.create(:build, repository: public_migrated_repo, private: false) }
    let(:public_migrated_job) { public_migrated_build.matrix.first }
    let(:authenticated_headers) {
      { 'HTTP_ACCEPT' => 'text/vnd.travis-ci.2+plain', 'HTTP_AUTHORIZATION' => "token #{token}" }
    }
    let(:headers) {
      { 'HTTP_ACCEPT' => 'text/vnd.travis-ci.2+plain' }
    }
    let(:v21_headers) {
      headers.dup.merge('HTTP_ACCEPT' => 'text/vnd.travis-ci.2.1+plain')
    }
    let(:v21_authenticated_headers) {
      authenticated_headers.dup.merge('HTTP_ACCEPT' => 'text/vnd.travis-ci.2.1+plain')
    }
    let(:private_job) { private_build.matrix.first }
    let(:public_job)  { public_build.matrix.first }

    before do
      private_job_id = private_job.id
      private_log = Travis::RemoteLog.new(content: 'private', job_id: private_job_id)
      remote = double('remote')
      allow(Travis::RemoteLog::Remote).to receive(:new).and_return(remote)
      allow(remote).to receive(:find_by_job_id).with(private_job_id).and_return(private_log)

      public_job_id = public_job.id
      public_log = Travis::RemoteLog.new(content: 'public', job_id: public_job_id)
      allow(remote).to receive(:find_by_job_id).with(public_job_id).and_return(public_log)
      # We expect to hit org as well as the migrated job references the public
      # job via its org_id.
      fallback_remote = double('fallback remote')
      allow(Travis::RemoteLog::Remote).to receive(:new).with(platform: :fallback).and_return(fallback_remote)
      allow(fallback_remote).to receive(:find_by_job_id).with(public_job_id).and_return(public_log)

      restarted_public_migrated_log = Travis::RemoteLog.new(content: 'public restarted', job_id: public_migrated_job.id)
      allow(remote).to receive(:find_by_job_id).with(public_migrated_job.id).and_return(restarted_public_migrated_log)
    end

    describe 'private mode, .com' do
      before { Travis.config.host = 'travis-ci.com' }
      after { Travis.config.host = 'travis-ci.org' }
      before { Travis.config[:public_mode] = false }

      describe 'given the current user has a permission on the repository' do
        it 'responds with a private log' do
          FactoryBot.create(:permission, user: user, repository: private_repo)
          response = get("/jobs/#{private_job.id}/log", {}, authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('private')
        end

        it 'responds with a public log' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          response = get("/jobs/#{public_job.id}/log", {}, authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'responds with 404 when fetching private log' do
          response = get("/jobs/#{private_job.id}/log", {}, authenticated_headers)
          expect(response).not_to be_ok
          expect(response.status).to eq(404)
        end

        it 'responds with 404 when fetching public log' do
          response = get("/jobs/#{public_job.id}/log", {}, authenticated_headers)
          expect(response).not_to be_ok
          expect(response.status).to eq(404)
        end
      end

      describe 'unauthenticated request' do
        it 'responds with 401 when fetching private log' do
          response = get("/jobs/#{private_job.id}/log", {}, headers)
          expect(response).not_to be_ok
          expect(response.status).to eq(401)
        end

        it 'responds with 401 when fetching public log' do
          response = get("/jobs/#{public_job.id}/log", {}, headers)
          expect(response).not_to be_ok
          expect(response.status).to eq(401)
        end
      end
    end

    describe 'public mode, .com v2' do
      before { Travis.config.host = 'travis-ci.com' }
      after { Travis.config.host = 'travis-ci.org' }
      before { Travis.config.public_mode = true }

      describe 'given the current user has a permission on the repository' do
        it 'responds with a private log' do
          FactoryBot.create(:permission, user: user, repository: private_repo)
          response = get("/jobs/#{private_job.id}/log", {}, authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('private')
          token = response.headers["X-Log-Access-Token"]
          expect(token).not_to be_nil

          response = get("/jobs/#{private_job.id}/log", {access_token: token}, headers)
          expect(response).to be_ok
          expect(response.body).to eq('private')
        end

        it 'responds with a public log' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          response = get("/jobs/#{public_job.id}/log", {}, authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
          expect(response.headers["X-Log-Access-Token"]).to be_nil
        end

        it 'responds with public log from .org when job already migrated not restarted' do
          public_migrated_job.update_attribute(:org_id, public_job.id)
          FactoryBot.create(:permission, user: user, repository: public_migrated_repo)
          response = get("/jobs/#{public_migrated_job.id}/log", {}, authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
          expect(response.headers["X-Log-Access-Token"]).to be_nil
        end

        it 'responds with public log from .com when job already migrated but since restarted' do
          public_migrated_job.update_attribute(:org_id, public_job.id)
          public_migrated_job.update_attribute(:restarted_at, 1.hour.ago)
          FactoryBot.create(:permission, user: user, repository: public_migrated_repo)
          response = get("/jobs/#{public_migrated_job.id}/log", {}, authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('public restarted')
          expect(response.headers["X-Log-Access-Token"]).to be_nil
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'responds with 404 when fetching private log' do
          response = get("/jobs/#{private_job.id}/log", {}, authenticated_headers)
          expect(response).not_to be_ok
          expect(response.status).to eq(404)
        end

        it 'responds with the log when fetching public log' do
          response = get("/jobs/#{public_job.id}/log", {}, authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
        end
      end

      describe 'unauthenticated request' do
        it 'responds with 401 when fetching private log' do
          response = get("/jobs/#{private_job.id}/log", {}, headers)
          expect(response).not_to be_ok
          expect(response.status).to eq(401)
        end

        it 'responds with 401 when fetching public log' do
          response = get("/jobs/#{public_job.id}/log", {}, headers)
          expect(response).not_to be_ok
          expect(response.status).to eq(401)
        end
      end
    end

    describe 'public mode, .com 2.1' do
      before { Travis.config.host = 'travis-ci.com' }
      after { Travis.config.host = 'travis-ci.org' }
      before { Travis.config.public_mode = true }

      describe 'given the current user has a permission on the repository' do
        it 'responds with a private log' do
          FactoryBot.create(:permission, user: user, repository: private_repo)
          response = get("/jobs/#{private_job.id}/log", {}, v21_authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('private')
          token = response.headers["X-Log-Access-Token"]
          expect(token).not_to be_nil

          response = get("/jobs/#{private_job.id}/log", {access_token: token}, v21_headers)
          expect(response).to be_ok
          expect(response.body).to eq('private')
        end

        it 'responds with a public log' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          response = get("/jobs/#{public_job.id}/log", {}, v21_authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
          expect(response.headers["X-Log-Access-Token"]).to be_nil
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'responds with 404 when fetching private log' do
          response = get("/jobs/#{private_job.id}/log", {}, v21_authenticated_headers)
          expect(response).not_to be_ok
          expect(response.status).to eq(404)
        end

        it 'responds with the log when fetching public log' do
          response = get("/jobs/#{public_job.id}/log", {}, v21_authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
        end
      end

      describe 'unauthenticated request' do
        it 'responds with 404 when fetching private log' do
          response = get("/jobs/#{private_job.id}/log", {}, v21_headers)
          expect(response).not_to be_ok
          expect(response.status).to eq(404)
        end

        it 'responds with the log when fetching public log' do
          response = get("/jobs/#{public_job.id}/log", {}, v21_headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
        end
      end
    end

    describe '.org' do
      before { Travis.config.host = 'travis-ci.org' }
      after { Travis.config.host = 'travis-ci.org' }
      before { Travis.config.public_mode = false }

      describe 'given the current user has a permission on the repository' do
        it 'responds with a public log' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          response = get("/jobs/#{public_job.id}/log", {}, authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
          expect(response.headers["X-Log-Access-Token"]).to be_nil
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'responds with the log when fetching public log' do
          response = get("/jobs/#{public_job.id}/log", {}, authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
        end
      end

      describe 'unauthenticated request' do
        it 'responds with the log when fetching public log' do
          response = get("/jobs/#{public_job.id}/log", {}, headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
        end
      end
    end
  end
end

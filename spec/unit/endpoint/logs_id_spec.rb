describe Travis::Api::App::Endpoint::Logs, set_app: true do
  after { Travis.config.public_mode = false }

  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 401) }

  context do
    let(:user) { FactoryBot.create(:user, login: :rkh) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:private_repo)   { FactoryBot.create(:repository, private: true) }
    let(:public_repo)    { FactoryBot.create(:repository, private: false) }
    let!(:private_build) { FactoryBot.create(:build, repository: private_repo, private: true) }
    let!(:public_build)  { FactoryBot.create(:build, repository: public_repo, private: false) }
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
      remote = double('remote')
      allow(Travis::RemoteLog::Remote).to receive(:new).and_return(remote)

      private_job_id = private_job.id
      private_log = Travis::RemoteLog.new(content: 'private', job_id: private_job_id, id: 1)
      allow(remote).to receive(:find_by_id).with(1).and_return(private_log)

      public_job_id = public_job.id
      public_log = Travis::RemoteLog.new(content: 'public', job_id: public_job_id, id: 2)
      allow(remote).to receive(:find_by_id).with(2).and_return(public_log)
    end

    describe 'private mode, .com' do
      before { Travis.config.host = 'travis-ci.com' }
      after { Travis.config.host = 'travis-ci.org' }
      before { Travis.config[:public_mode] = false }

      describe 'given the current user has a permission on the repository' do
        it 'responds with a private log' do
          FactoryBot.create(:permission, user: user, repository: private_repo)
          response = get("/logs/1", {}, authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('private')
        end

        it 'responds with a public log' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          response = get("/logs/2", {}, authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'responds with 404 when fetching private log' do
          response = get("/logs/1", {}, authenticated_headers)
          expect(response).not_to be_ok
          expect(response.status).to eq(404)
        end

        it 'responds with 404 when fetching public log' do
          response = get("/logs/2", {}, authenticated_headers)
          expect(response).not_to be_ok
          expect(response.status).to eq(404)
        end
      end

      describe 'unauthenticated request' do
        it 'responds with 401 when fetching private log' do
          response = get("/logs/1", {}, headers)
          expect(response).not_to be_ok
          expect(response.status).to eq(401)
        end

        it 'responds with 401 when fetching public log' do
          response = get("/logs/2", {}, headers)
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
          response = get("/logs/1", {}, authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('private')
        end

        it 'responds with a public log' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          response = get("/logs/2", {}, authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'responds with 404 when fetching private log' do
          response = get("/logs/1", {}, authenticated_headers)
          expect(response).not_to be_ok
          expect(response.status).to eq(404)
        end

        it 'responds with the log when fetching public log' do
          response = get("/logs/2", {}, authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
        end
      end

      describe 'unauthenticated request' do
        it 'responds with 401 when fetching private log' do
          response = get("/logs/1", {}, headers)
          expect(response).not_to be_ok
          expect(response.status).to eq(401)
        end

        it 'responds with 401 when fetching public log' do
          response = get("/logs/2", {}, headers)
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
          response = get("/logs/1", {}, v21_authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('private')
        end

        it 'responds with a public log' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          response = get("/logs/2", {}, v21_authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
          expect(response.headers["X-Log-Access-Token"]).to be_nil
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'responds with 404 when fetching private log' do
          response = get("/logs/1", {}, v21_authenticated_headers)
          expect(response).not_to be_ok
          expect(response.status).to eq(404)
        end

        it 'responds with the log when fetching public log' do
          response = get("/logs/2", {}, v21_authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
        end
      end

      describe 'unauthenticated request' do
        it 'responds with 404 when fetching private log' do
          response = get("/logs/1", {}, v21_headers)
          expect(response).not_to be_ok
          expect(response.status).to eq(404)
        end

        it 'responds with the log when fetching public log' do
          response = get("/logs/2", {}, v21_headers)
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
          response = get("/logs/2", {}, authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'responds with the log when fetching public log' do
          response = get("/logs/2", {}, authenticated_headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
        end
      end

      describe 'unauthenticated request' do
        it 'responds with the log when fetching public log' do
          response = get("/logs/2", {}, headers)
          expect(response).to be_ok
          expect(response.body).to eq('public')
        end
      end
    end
  end
end

describe Travis::Api::App::Endpoint::Logs, set_app: true do
  after { Travis.config.public_mode = false }

  context do
    let(:user) { Factory.create(:user, login: :rkh) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:private_repo)   { Factory.create(:repository, private: true) }
    let(:public_repo)    { Factory.create(:repository, private: false) }
    let!(:private_build) { Factory.create(:build, repository: private_repo, private: true) }
    let!(:public_build)  { Factory.create(:build, repository: public_repo, private: false) }
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
      private_log = Travis::RemoteLog.new(content: 'private', job_id: private_job_id, id: 1)
      Travis::RemoteLog.stubs(:find_by_id).with(1).returns(private_log)

      public_job_id = public_job.id
      public_log = Travis::RemoteLog.new(content: 'public', job_id: public_job_id, id: 2)
      Travis::RemoteLog.stubs(:find_by_id).with(2).returns(public_log)
    end

    describe 'private mode, .com' do
      before { Travis.config.host = 'travis-ci.com' }
      after { Travis.config.host = 'travis-ci.org' }
      before { Travis.config[:public_mode] = false }

      describe 'given the current user has a permission on the repository' do
        it 'responds with a private log' do
          Factory.create(:permission, user: user, repository: private_repo)
          response = get("/logs/1", {}, authenticated_headers)
          response.should be_ok
          response.body.should == 'private'
        end

        it 'responds with a public log' do
          Factory.create(:permission, user: user, repository: public_repo)
          response = get("/logs/2", {}, authenticated_headers)
          response.should be_ok
          response.body.should == 'public'
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'responds with 404 when fetching private log' do
          response = get("/logs/1", {}, authenticated_headers)
          response.should_not be_ok
          response.status.should == 404
        end

        it 'responds with 404 when fetching public log' do
          response = get("/logs/2", {}, authenticated_headers)
          response.should_not be_ok
          response.status.should == 404
        end
      end

      describe 'unauthenticated request' do
        it 'responds with 401 when fetching private log' do
          response = get("/logs/1", {}, headers)
          response.should_not be_ok
          response.status.should == 401
        end

        it 'responds with 401 when fetching public log' do
          response = get("/logs/2", {}, headers)
          response.should_not be_ok
          response.status.should == 401
        end
      end
    end

    describe 'public mode, .com v2' do
      before { Travis.config.host = 'travis-ci.com' }
      after { Travis.config.host = 'travis-ci.org' }
      before { Travis.config.public_mode = true }

      describe 'given the current user has a permission on the repository' do
        it 'responds with a private log' do
          Factory.create(:permission, user: user, repository: private_repo)
          response = get("/logs/1", {}, authenticated_headers)
          response.should be_ok
          response.body.should == 'private'
        end

        it 'responds with a public log' do
          Factory.create(:permission, user: user, repository: public_repo)
          response = get("/logs/2", {}, authenticated_headers)
          response.should be_ok
          response.body.should == 'public'
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'responds with 404 when fetching private log' do
          response = get("/logs/1", {}, authenticated_headers)
          response.should_not be_ok
          response.status.should == 404
        end

        it 'responds with the log when fetching public log' do
          response = get("/logs/2", {}, authenticated_headers)
          response.should be_ok
          response.body.should == 'public'
        end
      end

      describe 'unauthenticated request' do
        it 'responds with 401 when fetching private log' do
          response = get("/logs/1", {}, headers)
          response.should_not be_ok
          response.status.should == 401
        end

        it 'responds with 401 when fetching public log' do
          response = get("/logs/2", {}, headers)
          response.should_not be_ok
          response.status.should == 401
        end
      end
    end

    describe 'public mode, .com 2.1' do
      before { Travis.config.host = 'travis-ci.com' }
      after { Travis.config.host = 'travis-ci.org' }
      before { Travis.config.public_mode = true }

      describe 'given the current user has a permission on the repository' do
        it 'responds with a private log' do
          Factory.create(:permission, user: user, repository: private_repo)
          response = get("/logs/1", {}, v21_authenticated_headers)
          response.should be_ok
          response.body.should == 'private'
        end

        it 'responds with a public log' do
          Factory.create(:permission, user: user, repository: public_repo)
          response = get("/logs/2", {}, v21_authenticated_headers)
          response.should be_ok
          response.body.should == 'public'
          response.headers["X-Log-Access-Token"].should be_nil
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'responds with 404 when fetching private log' do
          response = get("/logs/1", {}, v21_authenticated_headers)
          response.should_not be_ok
          response.status.should == 404
        end

        it 'responds with the log when fetching public log' do
          response = get("/logs/2", {}, v21_authenticated_headers)
          response.should be_ok
          response.body.should == 'public'
        end
      end

      describe 'unauthenticated request' do
        it 'responds with 404 when fetching private log' do
          response = get("/logs/1", {}, v21_headers)
          response.should_not be_ok
          response.status.should == 404
        end

        it 'responds with the log when fetching public log' do
          response = get("/logs/2", {}, v21_headers)
          response.should be_ok
          response.body.should == 'public'
        end
      end
    end

    describe '.org' do
      before { Travis.config.host = 'travis-ci.org' }
      after { Travis.config.host = 'travis-ci.org' }
      before { Travis.config.public_mode = false }

      describe 'given the current user has a permission on the repository' do
        it 'responds with a public log' do
          Factory.create(:permission, user: user, repository: public_repo)
          response = get("/logs/2", {}, authenticated_headers)
          response.should be_ok
          response.body.should == 'public'
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'responds with the log when fetching public log' do
          response = get("/logs/2", {}, authenticated_headers)
          response.should be_ok
          response.body.should == 'public'
        end
      end

      describe 'unauthenticated request' do
        it 'responds with the log when fetching public log' do
          response = get("/logs/2", {}, headers)
          response.should be_ok
          response.body.should == 'public'
        end
      end
    end
  end
end

describe Travis::Api::App::Endpoint::Pusher, set_app: true do
  let(:sven)    { FactoryGirl.create(:user) }
  let(:rkh)     { FactoryGirl.create(:user, login: 'rkh', name: 'Konstantin Haase') }
  let(:travis)  { FactoryGirl.create(:repository, github_id: 200) }
  let(:sinatra) { FactoryGirl.create(:repository, name: 'sinatra', owner_name: 'sinatra', github_id: 300) }
  let(:build)   { FactoryGirl.create(:build, request: request) }
  let(:commit)  { FactoryGirl.create(:commit) }
  let(:request) { FactoryGirl.create(:request, owner: travis) }
  let(:job)     { FactoryGirl.create(:test, number: '3.1', queue: 'builds.linux', repository: travis, source: build) }
  let(:auth)    { JSON.parse(last_response.body)['channels'].map{ |channel, auth| "#{channel},#{auth}" }.join("\n") }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  describe 'when i am not signed in' do
    it 'returns a 401' do
      post '/pusher/auth', {}, headers
      last_response.status.should == 401
    end
  end

  describe 'when i am signed in' do
    let(:token) { Travis::Api::App::AccessToken.create(user: sven, app_id: -1) }

    before do
      headers['HTTP_AUTHORIZATION'] = "token #{token}"
      sven.permissions.create!(repository_id: travis.id, :push => true, :pull => true)
    end

    it 'authorizes my own user channel (private-user-:id)' do
      post '/pusher/auth', { channels: ["private-user-#{sven.id}"], :socket_id => '123.456' }, headers
      last_response.status.should == 200
      auth.should =~ /#{Travis.pusher.key}:.+$/
    end

    it "does not authorize another user's channel (private-user-:id)" do
      post '/pusher/auth', { channels: [ "private-user-#{rkh.id}.common"], :socket_id => '123.456' }, headers
      auth.should == ""
    end

    it 'authorizes a channel for repositories that i have permissions on (private-repo-:id)' do
      post '/pusher/auth', { channels: ["private-repo-#{travis.id}"], socket_id: '123.456' }, headers
      last_response.status.should == 200
      auth.should =~ /#{Travis.pusher.key}:.+$/
    end

    it "does not authorize a channel for a repository that i do not have permissions on (private-repo-:id)" do
      post '/pusher/auth', { channels: ["private-org-#{sinatra.id}"], socket_id: '123.456' }, headers
      auth.should == ""
    end

    describe 'job channels (private-job-:id)' do
      after { Travis.config.host = 'travis-ci.org' }
      after { Travis.config.public_mode = false }

      describe 'for a private repo' do
        before { job.update_attributes!(private: true) }

        it 'authorizes a channel for a job that belongs to a repository that i have permissions on' do
          post '/pusher/auth', { channels: ["private-job-#{job.id}"], socket_id: '123.456' }, headers
          last_response.status.should == 200
          auth.should =~ /#{Travis.pusher.key}:.+$/
        end

        it 'does not authorize a channel for a job that belongs to a repository that i do not have permissions on' do
          post '/pusher/auth', { channels: ["private-job-1"], socket_id: '123.456' }, headers
          last_response.status.should == 200
          auth.should == ""
        end
      end

      describe 'for a public repo (org)' do
        before { Travis.config.host = 'travis-ci.org' }
        before { Travis.config.public_mode = false }
        before { job.update_attributes!(private: false) }

        it 'authorizes a channel for a job that belongs to a repository that i have permissions on' do
          post '/pusher/auth', { channels: ["private-job-#{job.id}"], socket_id: '123.456' }, headers
          last_response.status.should == 200
          auth.should =~ /#{Travis.pusher.key}:.+$/
        end

        it 'authorizes a channel for a job that belongs to a repository that i do not have permissions on' do
          Permission.delete_all
          post '/pusher/auth', { channels: ["private-job-#{job.id}"], socket_id: '123.456' }, headers
          last_response.status.should == 200
          auth.should =~ /#{Travis.pusher.key}:.+$/
        end
      end

      describe 'for a public repo (public mode)' do
        before { Travis.config.host = 'travis-ci.com' }
        before { Travis.config.public_mode = true }
        before { job.update_attributes!(private: false) }

        it 'authorizes a channel for a job that belongs to a repository that i have permissions on' do
          post '/pusher/auth', { channels: ["private-job-#{job.id}"], socket_id: '123.456' }, headers
          last_response.status.should == 200
          auth.should =~ /#{Travis.pusher.key}:.+$/
        end

        it 'authorizes a channel for a job that belongs to a repository that i do not have permissions on' do
          Permission.delete_all
          post '/pusher/auth', { channels: ["private-job-#{job.id}"], socket_id: '123.456' }, headers
          last_response.status.should == 200
          auth.should =~ /#{Travis.pusher.key}:.+$/
        end
      end

      describe 'for a public repo (private mode)' do
        before { Travis.config.host = 'enterprise.travis-ci.com' }
        before { Travis.config.public_mode = false }
        before { job.update_attributes!(private: false) }

        it 'authorizes a channel for a job that belongs to a repository that i have permissions on' do
          post '/pusher/auth', { channels: ["private-job-#{job.id}"], socket_id: '123.456' }, headers
          last_response.status.should == 200
          auth.should =~ /#{Travis.pusher.key}:.+$/
        end

        it 'does not authorize a channel for a job that belongs to a repository that i do not have permissions on' do
          Permission.delete_all
          post '/pusher/auth', { channels: ["private-job-#{job.id}"], socket_id: '123.456' }, headers
          last_response.status.should == 200
          auth.should == ""
        end
      end
    end
  end
end

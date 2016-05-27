require 'spec_helper'

describe 'Builds' do
  let(:repo)  { Repository.by_slug('svenfuchs/minimal').first }
  let(:build) { repo.builds.first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  it 'GET /builds?repository_id=1' do
    response = get '/builds', { repository_id: repo.id }, headers
    response.should deliver_json_for(repo.builds.order('id DESC'), version: 'v2')
  end

  it 'GET /builds/1' do
    response = get "/builds/#{build.id}", {}, headers
    response.should deliver_json_for(build, version: 'v2')
  end

  it 'GET /builds/1?repository_id=1' do
    response = get "/builds/#{build.id}", { repository_id: repo.id }, headers
    response.should deliver_json_for(build, version: 'v2')
  end

  it 'GET /repos/svenfuchs/minimal/builds' do
    response = get '/repos/svenfuchs/minimal/builds', {}, headers
    response.should deliver_json_for(repo.builds.order('id DESC'), version: 'v2', type: :builds)
  end

  it 'GET /repos/svenfuchs/minimal/builds?ids=1,2' do
    ids = repo.builds.map(&:id).sort.join(',')
    response = get "/repos/svenfuchs/minimal/builds?ids=#{ids}", {}, headers
    response.should deliver_json_for(repo.builds.order('id ASC'), version: 'v2')
  end

  it 'GET /builds?ids=1,2' do
    ids = repo.builds.map(&:id).sort.join(',')
    response = get "/builds?ids=#{ids}", {}, headers
    response.should deliver_json_for(repo.builds.order('id ASC'), version: 'v2')
  end

  it 'GET /repos/svenfuchs/minimal/builds/1' do
    response = get "/repos/svenfuchs/minimal/builds/#{build.id}", {}, headers
    response.should deliver_json_for(build, version: 'v2')
  end

  it 'GET /builds/1?repository_id=1&branches=true' do
    response = get "/builds?repository_id=#{repo.id}&branches=true", {}, headers
    response.should deliver_json_for(repo.last_finished_builds_by_branches, version: 'v2')
  end

  describe 'POST /builds/:id/cancel' do
    let(:user)    { User.where(login: 'svenfuchs').first }
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }

    before {
      headers.merge! 'HTTP_AUTHORIZATION' => "token #{token}"
      user.permissions.create!(repository_id: build.repository.id, :pull => true, :push => true)
    }

    context 'when user does not have rights to cancel the build' do
      before { user.permissions.destroy_all }

      it 'responds with 403' do
        response = post "/builds/#{build.id}/cancel", {}, headers
        response.status.should == 403
      end

      context 'and enqueues cancel event for the Hub' do
        before { Travis::Features.activate_owner(:enqueue_to_hub, repo.owner) }

        it 'responds with 403' do
          response = post "/builds/#{build.id}/cancel", {}, headers
          response.status.should == 403
        end

      end
    end

    context 'when build is not cancelable' do
      before { build.matrix.each { |j| j.update_attribute(:state, 'passed') } }

      it 'responds with 422' do
        response = post "/builds/#{build.id}/cancel", {}, headers
        response.status.should == 422
      end

      context 'and enqueues cancel event for the Hub' do
        before { Travis::Features.activate_owner(:enqueue_to_hub, repo.owner) }

        it 'responds with 422' do
          response = post "/builds/#{build.id}/cancel", {}, headers
          response.status.should == 422
        end
      end
    end

    context 'when build can be canceled' do
      before do
        build.matrix.each { |j| j.update_attribute(:state, 'created') }
        build.update_attribute(:state, 'created')
      end

      context 'from the Core' do
        before { Travis::Sidekiq::BuildCancellation.stubs(:perform_async) }

        it 'cancels the build' do
          Travis::Sidekiq::BuildCancellation.expects(:perform_async).with( id: build.id.to_s, user_id: user.id, source: 'api')
          post "/builds/#{build.id}/cancel", {}, headers
        end

        it 'responds with 204' do
          response = post "/builds/#{build.id}/cancel", {}, headers
          response.status.should == 204
        end
      end

      context 'and enqueues cancel event for the Hub' do
        before { Travis::Features.activate_owner(:enqueue_to_hub, repo.owner) }

        before do
          build.matrix.each { |j| j.update_attribute(:state, 'created') }
          build.update_attribute(:state, 'created')
        end

        it 'cancels the build' do
          ::Sidekiq::Client.expects(:push).times(4)
          post "/builds/#{build.id}/cancel", {}, headers
        end

        it 'responds with 204' do
          ::Sidekiq::Client.expects(:push).times(4)
          response = post "/builds/#{build.id}/cancel", {}, headers
          response.status.should == 204
        end
      end
    end
  end

  describe 'POST /builds/:id/restart' do
    let(:user)    { User.where(login: 'svenfuchs').first }
    let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }

    before {
      headers.merge! 'HTTP_AUTHORIZATION' => "token #{token}"
      user.permissions.create!(repository_id: build.repository.id, :pull => true, :push => true)
    }

    context 'when restart is not acceptable' do
      before { user.permissions.destroy_all }

      it 'responds with 400' do
        response = post "/builds/#{build.id}/restart", {}, headers
        response.status.should == 400
      end
    end

    context 'when build passed' do
      before do
        build.matrix.each { |j| j.update_attribute(:state, 'passed') }
        build.update_attribute(:state, 'passed')
      end

      describe 'Enqueues restart event for the Hub' do
        before { Travis::Features.activate_owner(:enqueue_to_hub, repo.owner) }

        it 'restarts the build' do
          ::Sidekiq::Client.expects(:push)
          response = post "/builds/#{build.id}/restart", {}, headers
          response.status.should == 202
        end

        it 'sends the correct response body' do
          ::Sidekiq::Client.expects(:push)
          response = post "/builds/#{build.id}/restart", {}, headers
          body = JSON.parse(response.body)
          body.should == {"result"=>true, "flash"=>[{"notice"=>"The build was successfully restarted."}]}
        end
      end

      describe 'Restart from the Core' do
        before { Travis::Sidekiq::BuildRestart.stubs(:perform_async) }

        it 'restarts the build' do
          Travis::Sidekiq::BuildRestart.expects(:perform_async).with(id: build.id.to_s, user_id: user.id)
          response = post "/builds/#{build.id}/restart", {}, headers
          response.status.should == 202
        end

        it 'sends the correct response body' do
          Travis::Sidekiq::BuildRestart.expects(:perform_async).with(id: build.id.to_s, user_id: user.id)
          response = post "/builds/#{build.id}/restart", {}, headers
          body = JSON.parse(response.body)
          body.should == {"result"=>true, "flash"=>[{"notice"=>"The build was successfully restarted."}]}
        end
      end
    end
  end
end

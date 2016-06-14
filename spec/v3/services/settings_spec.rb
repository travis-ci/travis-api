describe Travis::API::V3::Services::Settings, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }

  describe :Find do
    describe 'not authenticated' do
      before { get("/v3/repo/#{repo.id}/settings") }
      include_examples 'not authenticated'
    end

    describe 'authenticated, missing repo' do
      before { get('/v3/repo/9999999999/settings', {}, auth_headers) }

      example { expect(last_response.status).to eq(404) }
      example do
        expect(JSON.load(body)).to eq(
          '@type' => 'error',
          'error_type' => 'not_found',
          'error_message' => 'repository not found (or insufficient access)',
          'resource_type' => 'repository'
        )
      end
    end

    describe 'authenticated, existing repo, repo has no settings' do
      before { get("/v3/repo/#{repo.id}/settings", {}, auth_headers) }

      example { expect(last_response.status).to eq(200) }
      example do
        expect(JSON.load(body)).to eq(
          '@type' => 'settings',
          'builds_only_with_travis_yml' => false,
          'build_pushes' => true,
          'build_pull_requests' => true,
          'maximum_number_of_builds' => 0
        )
      end
    end

    describe 'authenticated, existing repo, repo has some settings' do
      before do
        repo.update_attributes(settings: JSON.dump('build_pushes' => false))
        get("/v3/repo/#{repo.id}/settings", {}, auth_headers)
      end

      example { expect(last_response.status).to eq(200) }
      example do
        expect(JSON.load(body)).to eq(
          '@type' => 'settings',
          'builds_only_with_travis_yml' => false,
          'build_pushes' => false,
          'build_pull_requests' => true,
          'maximum_number_of_builds' => 0
        )
      end
    end
  end

  describe :Update do
    describe 'not authenticated' do
      before do
        patch("/v3/repo/#{repo.id}/settings", JSON.dump(build_pushes: false), json_headers)
      end

      example { expect(last_response.status).to eq(403) }
      example do
        expect(JSON.load(body)).to eq(
          '@type' => 'error',
          'error_type' => 'login_required',
          'error_message' => 'login required'
        )
      end
    end

    describe 'authenticated, missing repo' do
      before do
        patch('/v3/repo/9999999999/settings', JSON.dump(build_pushes: false), json_headers.merge(auth_headers))
      end

      example { expect(last_response.status).to eq(404) }
      example do
        expect(JSON.load(body)).to eq(
          '@type' => 'error',
          'error_type' => 'not_found',
          'error_message' => 'repository not found (or insufficient access)',
          'resource_type' => 'repository'
        )
      end
    end

    describe 'authenticated, existing repo' do
      let(:params) { JSON.dump('settings.build_pushes' => false) }

      before do
        repo.update_attributes(settings: JSON.dump('maximum_number_of_builds' => 20))
        patch("/v3/repo/#{repo.id}/settings", params, json_headers.merge(auth_headers))
      end

      example { expect(last_response.status).to eq(200) }
      example do
        expect(JSON.load(body)).to eq(
          '@type' => 'settings',
          'builds_only_with_travis_yml' => false,
          'build_pushes' => false,
          'build_pull_requests' => true,
          'maximum_number_of_builds' => 20
        )
      end
    end
  end
end

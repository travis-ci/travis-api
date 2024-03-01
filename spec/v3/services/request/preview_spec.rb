describe Travis::API::V3::Services::Request::Preview, set_app: true do
  let(:repo) { FactoryBot.create(:repository_without_last_build, owner_name: 'svenfuchs', name: 'minimal') }
  let(:request) { Travis::API::V3::Models::Request.last }
  let(:env_var) { { id: nil, name: 'ONE', value: Travis::Settings::EncryptedValue.new('one'), public: true, branch: 'foo', repository_id: repo.id } }

  let(:body) { parse(last_response.body) }
  let(:status) { last_response.status }

  let(:configs) do
    {
      raw_configs: [source: 'travis-ci/travis-yml:.travis.yml@ref', config: 'script: true', mode: 'replace'],
      config: { script: ['true'] },
      matrix: [script: ['true']],
      messages: [type: :type, level: :info, key: :key, code: :code, args: { one: 'one' }, src: '.travis.yml', line: 1],
      full_messages: ['message']
    }
  end

  before { repo.update(settings: { env_vars: [env_var] }) }
  before { stub_request(:post, 'https://yml.travis-ci.org/configs').to_return(status: 200, body: JSON.dump(configs)) }

  let(:authorization) { { 'permissions' => ['repository_build_create'] } }

  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  def parse(str)
    JSON.parse(str).deep_symbolize_keys
  end

  describe 'not authenticated' do
    let(:authorization) { { 'permissions' => [] } }
    before { post("/v3/repo/#{repo.id}/request/preview") }
    it { expect(status).to eq 403 }
    it do
      expect(body).to eq(
        '@type': 'error',
        'error_type': 'login_required',
        'error_message': 'login required'
      )
    end
  end

  describe 'authenticated' do
    let(:params) { { ref: 'master', configs: [config: '', mode: :deep_merge] } }
    let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
    before { post("/v3/repo/#{repo.id}/request/config", params, headers) }

    it { expect(status).to eq 200 }

    it do
      expect(body).to eq(
        '@type': 'request_preview',
        '@representation': 'standard',
        raw_configs: [
          '@type': 'request_raw_configuration',
          '@representation': 'minimal',
          source: 'travis-ci/travis-yml:.travis.yml@ref',
          merge_mode: 'replace',
          config: 'script: true'
        ],
        request_config: {
          '@type': 'request_config',
          '@representation': 'minimal',
          config: {
            script: [
              'true'
            ]
          }
        },
        job_configs: [
          '@type': 'job_config',
          '@representation': 'minimal',
          config: {
            script: [
              'true'
            ]
          }
        ],
        messages: [
          '@type': 'message',
          '@representation': 'minimal',
          id: nil,
          # type: 'type',
          level: 'info',
          key: 'key',
          code: 'code',
          args: {
            one: 'one'
          },
          src: '.travis.yml',
          line: 1
        ],
        full_messages: [
          'message'
        ]
      )
    end

    it do
      expect(WebMock).to have_requested(:post, %r(/configs)).with { |req|
        expect(parse(req.body)).to eq(
          repo: {
            github_id: repo.github_id,
            slug: repo.slug,
            token: 'github_oauth_token',
            private: false,
            default_branch: 'master',
            allow_config_imports: nil,
            private_key: nil
          },
          ref: 'master',
          configs: [
            config: '',
            mode: 'deep_merge',
          ],
          data: {
            repo: repo.slug,
            fork: false,
            env: [
              ONE: 'one'
            ]
          }
        )
      }

      # these are per request, so clients would have to send these manually
      #
      # data: {
      #   type: 'push',
      #   head_repo: nil,
      #   sender: nil,
      #   branch: 'master',
      #   head_branch: nil,
      #   tag: nil,
      #   commit_message: 'the commit message',
      # }
    end
  end
end

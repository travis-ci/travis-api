describe Travis::API::V3::Services::Request::Find, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:request) { repo.requests.first }

  describe "retrieve request on a public repository" do
    before { get("/v3/repo/#{repo.id}/request/#{request.id}")     }

    it { expect(last_response).to be_ok }

    it do
      expect(JSON.load(body).to_s).to include(
        "@type",
        "request",
        "/v3/repo/#{repo.id}/request",
        "id",
        "state",
        "message",
        "result",
        "builds",
        "@representation",
        "repository",
        "owner",
        "event_type",
        "push",
        "base_commit",
        "head_commit",
        "pull_request_mergeable"
      )
    end
  end

  describe "include config" do
    before { request.update!(config: { language: :ruby }) }
    before { get("/v3/repo/#{repo.id}/request/#{request.id}?include=request.config") }
    subject { JSON.load(body)['config'] }
    it { should eq 'language' => 'ruby' }
  end

  describe "include raw configs" do
    let(:one) { request.raw_configs.build(key: '123', config: 'language: ruby') }
    let(:two) { request.raw_configs.build(key: '234', config: 'rvm: 2.5.1') }

    before { request.raw_configurations.create!(raw_config: one, source: '.travis.yml', merge_mode: 'one') }
    before { request.raw_configurations.create!(raw_config: two, source: 'other.yml', merge_mode: 'two') }
    before { request.raw_configurations.create!(raw_config: one, source: '.travis.yml', merge_mode: 'one') } # accidental duplicate

    before { get("/v3/repo/#{repo.id}/request/#{request.id}?include=request.raw_configs") }

    subject { JSON.load(body)['raw_configs'] }

    it do
      should eq(
        [
          {
            '@type' => 'request_raw_configuration',
            '@representation' => 'standard',
            'config' => 'language: ruby',
            'source' => '.travis.yml',
            'merge_mode' => 'one',
          },
          {
            '@type' => 'request_raw_configuration',
            '@representation' => 'standard',
            'config' => 'rvm: 2.5.1',
            'source' => 'other.yml',
            'merge_mode' => 'two',
          }
        ]
      )
    end
  end

  describe "include yaml config" do
    subject { JSON.load(body)['yaml_config'] }
    let(:yaml_config) { Travis::API::V3::Models::RequestYamlConfig.new(key: '123', yaml: 'rvm: 2.5.1') }
    before { request.update!(yaml_config: yaml_config) }
    before { get("/v3/repo/#{repo.id}/request/#{request.id}?include=request.yaml_config") }

    it { should eq 'rvm: 2.5.1' }

    it 'is deprecated' do
      expect(JSON.load(body)['@warnings']).to eq([
        '@type' => 'warning',
        'message' => 'request.yaml_config will soon be deprecated. Please use request.raw_configs instead',
        'warning_type' => 'deprecated_parameter',
        'parameter' => 'request.yaml_config'
      ])
    end
  end

  describe 'include messages' do
    before { Travis::API::V3::Models::Message.create!(level: 'warn', subject_id: request.id, subject_type: 'Request')}
    before { get("/v3/repo/#{repo.id}/request/#{request.id}?include=request.messages") }
    subject { JSON.load(body)['messages'][0]['@type'] }
    it { should eq 'message' }
  end

  describe "retrieve request on private repository, private API, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before { repo.update_attribute(:private, true) }
    before { get("/v3/repo/#{repo.id}/request/#{request.id}", {}, headers) }

    it { expect(last_response).to be_ok }

    it do
      expect(JSON.load(body).to_s).to include(
        "@type",
        "request",
        "/v3/repo/#{repo.id}/request",
        "id",
        "state",
        "message",
        "result",
        "builds",
        "@representation",
        "repository",
        "owner",
        "event_type",
        "push",
        "base_commit",
        "head_commit"
      )
    end
  end
end

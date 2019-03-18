describe Travis::API::V3::Services::Request::Find, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:request) { repo.requests.first }

  describe "retrieve request on a public repository" do
    before     { get("/v3/repo/#{repo.id}/request/#{request.id}")     }
    example    { expect(last_response).to be_ok }
    example    { expect(JSON.load(body).to_s).to include(
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
                  "head_commit")
    }
  end

  describe "include raw configs" do
    let(:raw_config) { request.raw_configs.build(key: '123', config: 'rvm: 2.5.1') }
    subject { JSON.load(body)['raw_configs'] }
    before { request.raw_configurations.create!(raw_config: raw_config, source: '.travis.yml') }
    before { get("/v3/repo/#{repo.id}/request/#{request.id}?include=request.raw_configs") }

    it do
      should eq([
        '@type' => 'request_raw_configuration',
        '@representation' => 'standard',
        'config' => 'rvm: 2.5.1',
        'source' => '.travis.yml'
      ])
    end
  end

  describe "include yaml config" do
    subject { JSON.load(body)['yaml_config'] }
    let(:yaml_config) { Travis::API::V3::Models::RequestYamlConfig.new(key: '123', yaml: 'rvm: 2.5.1') }
    before { request.update_attributes!(yaml_config: yaml_config) }
    before { get("/v3/repo/#{repo.id}/request/#{request.id}?include=request.yaml_config") }

    it { should eq 'rvm: 2.5.1' }
  end

  describe "retrieve request on private repository, private API, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/repo/#{repo.id}/request/#{request.id}", {}, headers)                             }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(JSON.load(body).to_s).to include(
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
                      "head_commit")
    }

  end
end

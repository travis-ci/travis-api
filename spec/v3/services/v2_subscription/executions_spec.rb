describe Travis::API::V3::Services::Executions, set_app: true, billing_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }

  before do
    Travis.config.host = 'travis-ci.com'
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      get('/v3/owner/123/executions')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user, login: 'travis-ci') }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    let(:invoice_id) { "TP#{rand(999)}" }
    let(:created_at) { '2018-04-17T18:30:32Z' }
    let(:url) { 'https://billing-test.travis-ci.com/invoices/111.pdf' }
    let(:amount_due) { 100 }
    let(:status) { 'paid' }
    let(:subscription_id) { rand(999) }
    let(:page) { 1 }
    let(:per_page) { 25 }
    let(:from) { Date.today - 2.months }
    let(:to) { Date.today }
    before do
      stub_request(:get, "#{billing_url}/usage/users/#{user.id}/executions?page=#{page}&per_page=#{per_page}&from=#{from.to_s}&to=#{to.to_s}")
        .with(basic_auth: ['_', billing_auth_key],  headers: { 'X-Travis-User-Id' => user.id })
        .to_return(body: JSON.dump([billing_executions_response_body]))
      stub_request(:get, "#{billing_url}/usage/users/#{user.id}/executions?page=0&per_page=0&from=#{from.to_s}&to=#{to.to_s}")
        .with(basic_auth: ['_', billing_auth_key],  headers: { 'X-Travis-User-Id' => user.id })
        .to_return(body: JSON.dump([billing_executions_response_body]))
    end

    it 'responds with list of executions' do
      get("/v3/owner/#{user.login}/executions?page=#{page}&per_page=#{per_page}&from=#{from.to_s}&to=#{to.to_s}", {}, headers)

      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json({
        '@type' => 'executions',
        '@href' => "/v3/owner/travis-ci/executions?page=1&per_page=25&from=#{from.to_s}&to=#{to.to_s}",
        '@representation' => 'standard',
        'executions' => [{
          '@type' => 'execution',
          '@representation' => 'standard',
          'id' => 1,
          'os' => 'linux',
          'instance_size' => 'standard-2',
          'arch' => 'amd64',
          'virtualization_type' => 'vm',
          'queue' => 'builds.gce-oss',
          'job_id' => 123,
          'repository_id' => repo.id,
          'owner_id' => 1,
          'owner_type' => 'User',
          'plan_id' => 2,
          'sender_id' => 1,
          'credits_consumed' => 5,
          'started_at' => Time.now.to_s,
          'finished_at' => (Time.now + 10.minutes).to_s,
          'created_at' => Time.now.to_s,
          'updated_at' => Time.now.to_s
        }]
      })
    end

    it 'responds with list of executions per repo' do
      get("/v3/owner/#{user.login}/executions_per_repo?from=#{from.to_s}&to=#{to.to_s}", {}, headers)

      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json({
        '@type' => 'executionsperrepo',
        '@href' => "/v3/owner/travis-ci/executions_per_repo?from=#{from.to_s}&to=#{to.to_s}",
        '@representation' => 'standard',
        'executionsperrepo' =>
        [
          {
            "repository_id"=>1,
            "os"=>"linux",
            "credits_consumed"=>5,
            "minutes_consumed"=>10,
            "repository"=>
            {
              "@type"=>"repository",
              "@href"=>"/repo/1",
              "@representation"=>"standard",
              "@permissions"=>
              {
                "read"=>true,
                "activate"=>false,
                "deactivate"=>false,
                "migrate"=>false,
                "star"=>false,
                "unstar"=>false,
                "create_cron"=>false,
                "create_env_var"=>false,
                "create_key_pair"=>false,
                "delete_key_pair"=>false,
                "create_request"=>false,
                "admin"=>false
              },
              "id"=>1,
              "name"=>"minimal",
              "slug"=>"svenfuchs/minimal",
              "description"=>nil,
              "github_id"=>1,
              "vcs_id"=>nil,
              "vcs_type"=>"GithubRepository",
              "github_language"=>nil,
              "active"=>true,
              "private"=>false,
              "owner"=>{"@type"=>"user", "id"=>1, "login"=>"svenfuchs", "@href"=>"/user/1", "ro_mode"=>false},
              "owner_name"=>"svenfuchs",
              "vcs_name"=>"minimal",
              "default_branch"=>{"@type"=>"branch", "@href"=>"/repo/1/branch/master", "@representation"=>"minimal", "name"=>"master"},
              "starred"=>false,
              "managed_by_installation"=>false,
              "active_on_org"=>nil,
              "migration_status"=>nil,
              "history_migration_status"=>nil,
              "shared"=>false,
              "config_validation"=>false
            }
          }
        ]
      })
    end

    it 'responds with list of executions per sender' do
      get("/v3/owner/#{user.login}/executions_per_sender?from=#{from.to_s}&to=#{to.to_s}", {}, headers)

      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json({
        '@type' => 'executionspersender',
        '@href' => "/v3/owner/travis-ci/executions_per_sender?from=#{from.to_s}&to=#{to.to_s}",
        '@representation' => 'standard',
        'executionspersender' =>
        [
          {
            "credits_consumed"=>5,
            "minutes_consumed"=>10,
            "sender_id"=>1,
            "sender"=>
            {
              "@type"=>"user",
              "@href"=>"/user/1",
              "@representation"=>"standard",
              "@permissions"=>{"read"=>true, "sync"=>false},
              "id"=>1,
              "login"=>"svenfuchs",
              "name"=>"Sven Fuchs",
              "github_id"=>nil,
              "vcs_id"=>nil,
              "vcs_type"=>"GithubUser",
              "avatar_url"=>"https://0.gravatar.com/avatar/07fb84848e68b96b69022d333ca8a3e2",
              "education"=>nil,
              "allow_migration"=>false,
              "allowance"=>
              {
                "@type"=>"allowance",
                "@representation"=>"minimal",
                "id"=>1
              },
              "email"=>"sven@fuchs.com",
              "is_syncing"=>nil,
              "synced_at"=>nil,
              "recently_signed_up"=>false,
              "secure_user_hash"=>nil,
              "ro_mode" => false
            }
          }
        ]}
      )
    end
  end
end

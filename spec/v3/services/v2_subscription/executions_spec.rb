describe Travis::API::V3::Services::Executions, set_app: true, billing_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }

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
    end

    it 'responds with list of executions' do
      get("/v3/owner/#{user.login}/executions?page=#{page}&per_page=#{per_page}&from=#{from.to_s}&to=#{to.to_s}", {}, headers)

      expect(last_response.status).to eq(200)
      puts parsed_body
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
          'repository_id' => 123,
          'owner_id' => 1,
          'owner_type' => 'User',
          'plan_id' => 2,
          'sender_id' => 1,
          'credits_consumed' => 5,
          'started_at' => Time.now.to_s,
          'finished_at' => Time.now.to_s,
          'created_at' => Time.now.to_s,
          'updated_at' => Time.now.to_s
        }]
      })
    end
  end
end

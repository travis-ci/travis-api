describe Travis::API::V3::Services::Insights::Metrics, set_app: true do
  let(:organization) { Factory(:org) }
  let(:user) { Factory(:user) }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:authenticated_headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
  let(:anonymous_headers) {{}}
  let(:expected_data) { { 'metrics' => ['whatever'] } }
  let(:insights_url) { "#{Travis.config.insights.endpoint}/metrics?owner_type=#{owner_type}&owner_id=#{owner_id}&rest-of-params=value" }
  let(:stubbed_response_status) { 200 }
  let(:stubbed_response_body) { JSON.dump(expected_data) }
  let(:stubbed_response_headers) {{ content_type: 'application/json' }}

  let!(:stubbed_request) do
    stub_request(:get, insights_url).with(headers: { 'Authorization' => "Token token=\"#{Travis.config.insights.auth_token}\""}).to_return(status: stubbed_response_status, body: stubbed_response_body, headers: stubbed_response_headers)
  end

  before do
    Travis.config.host = "travis-ci.#{site}"
  end

  subject(:response) { get("/v3/insights/metrics?owner_type=#{owner_type}&owner_id=#{owner_id}&rest-of-params=value", {}, headers) }

  shared_examples_for 'proxies the request' do
    it 'requests the metrics from the insights service' do
      expect(response.status).to eq(200)
      response_data = JSON.parse(response.body)
      expect(response_data['data']).to eq(expected_data)
      expect(response_data['@warnings']).to eq nil # no warnings about passing unexpected params
    end

    context 'when something fails' do
      let(:stubbed_response_status) { 400 }
      let(:stubbed_response_body) { 'This is an error message' }
      let(:stubbed_response_headers) {{ content_type: 'text/plain'}}

      it 'returns the same error' do
        expect(response.status).to eq(400)
        response_data = JSON.parse(response.body)
        expect(response_data['data']).to eq('This is an error message')
        expect(response_data['@warnings']).to eq nil # no warnings about passing unexpected params
      end
    end

    context 'when the wrong owner_type is passed' do
      let(:owner_type) { 'Repository' }

      it_behaves_like 'blocks the request', 400
    end
  end

  shared_examples_for 'blocks the request' do |status|
    it "responds with #{status} and does not do any request" do
      expect(response.status).to eq(status)
      expect(stubbed_request).to_not have_been_made
    end
  end

  context 'in .org' do # TL;DR: proxies always
    let(:site) { :org }

    context 'unauthenticated' do
      let(:headers) { anonymous_headers }

      context 'for a user' do
        let(:owner_type) { 'User' }
        let(:owner_id) { Factory(:user).id }

        it_behaves_like 'proxies the request'
      end

      context 'for an organization' do
        let(:owner_type) { 'Organization' }
        let(:owner_id) { Factory(:org).id }

        it_behaves_like 'proxies the request'
      end
    end

    context 'authenticated' do
      let(:headers) { authenticated_headers }

      context 'for a user' do
        let(:owner_type) { 'User' }

        context 'themselves' do
          let(:owner_id) { user.id }

          it_behaves_like 'proxies the request'
        end

        context 'a different one' do
          let(:owner_id) { Factory(:user).id }

          it_behaves_like 'proxies the request'
        end
      end

      context 'for an organization' do
        let(:owner_type) { 'Organization' }

        context 'they belong to' do
          let(:owner_id) { organization.id }

          before do
            organization.memberships.create!(user: user, role: role)
          end

          context 'as admin' do
            let(:role) { 'admin' }
            it_behaves_like 'proxies the request'
          end

          context 'as simple user' do
            let(:role) { 'member' }
            it_behaves_like 'proxies the request'
          end
        end

        context 'a different one' do
          let(:owner_id) { Factory(:org).id }

          it_behaves_like 'proxies the request'
        end
      end
    end
  end

  context 'in .com' do
    let(:site) { :com }
    let(:insights_url) { super() + "&private=#{expected_private_flag}" }

    context 'unauthenticated' do # TL;DR: block everything
      let(:headers) { anonymous_headers }

      context 'for a user' do
        let(:owner_type) { 'User' }
        let(:owner_id) { Factory(:user).id }

        let(:expected_private_flag) { false }

        it_behaves_like 'proxies the request'
      end

      context 'for an organization' do
        let(:owner_type) { 'Organization' }
        let(:owner_id) { Factory(:org).id }

        let(:expected_private_flag) { false }

        it_behaves_like 'proxies the request'
      end
    end

    context 'authenticated' do
      let(:headers) { authenticated_headers }

      context 'for a user' do
        let(:owner_type) { 'User' }

        context 'themselves' do
          let(:owner_id) { user.id }

          let(:expected_private_flag) { true }

          it_behaves_like 'proxies the request'
        end

        context 'a different one' do
          let(:owner_id) { Factory(:user).id }

          let(:expected_private_flag) { false }

          it_behaves_like 'proxies the request'
        end
      end

      context 'for an organization' do
        let(:owner_type) { 'Organization' }

        context 'they belong to' do
          let(:owner_id) { organization.id }

          before do
            organization.memberships.create!(user: user, role: role)
          end

          context 'as admin' do
            let(:role) { 'admin' }

            let(:expected_private_flag) { true }

            it_behaves_like 'proxies the request'
          end

          context 'as simple user' do
            let(:role) { 'member' }

            let(:expected_private_flag) { false }

            it_behaves_like 'proxies the request'
          end
        end

        context 'a different one' do
          let(:owner_id) { Factory(:org).id }

          let(:expected_private_flag) { false }

          it_behaves_like 'proxies the request'
        end
      end
    end
  end
end

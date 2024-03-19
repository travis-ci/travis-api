describe Travis::API::V3::Services::Insights::Metrics, set_app: true do
  let(:organization) { FactoryBot.create(:org) }
  let(:user) { FactoryBot.create(:user) }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:authenticated_headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
  let(:anonymous_headers) {{}}
  let(:expected_data) { { 'metrics' => ['whatever'] } }
  let(:insights_url) { "#{Travis.config.insights.endpoint}/metrics?owner_type=#{owner_type}&owner_id=#{owner_id}&private=#{expected_private_flag}&rest-of-params=value" }
  let(:stubbed_response_status) { 200 }
  let(:stubbed_response_body) { JSON.dump(expected_data) }
  let(:stubbed_response_headers) {{ content_type: 'application/json' }}

  let!(:stubbed_request) do
    stub_request(:get, insights_url).to_return(status: stubbed_response_status, body: stubbed_response_body, headers: stubbed_response_headers)
  end

  before do
    Travis.config.host = "travis-ci.#{site}"
  end

  subject(:response) { get("/v3/insights/metrics?owner_type=#{owner_type}&owner_id=#{owner_id}&private=#{passed_private_flag}&rest-of-params=value", {}, headers) }

  shared_examples_for 'proxies the request' do |variables = {}|
    variables.each do |variable, value|
      let(variable) { value }
    end

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

      it "responds with 400 and does not do any request" do
        expect(response.status).to eq(400)
        expect(stubbed_request).to_not have_been_made
      end
    end
  end

  context 'in .org' do
    let(:site) { :org }
    let(:passed_private_flag) { false }
    let(:expected_private_flag) { false }

    context 'unauthenticated' do
      let(:headers) { anonymous_headers }

      context 'for a user' do
        let(:owner_type) { 'User' }
        let(:owner_id) { FactoryBot.create(:user).id }

        it_behaves_like 'proxies the request'
      end

      context 'for an organization' do
        let(:owner_type) { 'Organization' }
        let(:owner_id) { FactoryBot.create(:org).id }

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
          let(:owner_id) { FactoryBot.create(:user).id }

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
          let(:owner_id) { FactoryBot.create(:org).id }

          it_behaves_like 'proxies the request'
        end
      end
    end
  end

  context 'in .com' do
    let(:site) { :com }
    let(:passed_private_flag) { true }
    let(:expected_private_flag) { false } # this combination is the "safest" (don't request private from insights even
                                          # if it was passed to API). We'll override for the specific cases where this
                                          # is not the case, i.e. users with permissions

    context 'unauthenticated' do
      let(:headers) { anonymous_headers }

      context 'for a user' do
        let(:owner_type) { 'User' }
        let(:owner_id) { FactoryBot.create(:user).id }

        it_behaves_like 'proxies the request', expected_private_flag: false
      end

      context 'for an organization' do
        let(:owner_type) { 'Organization' }
        let(:owner_id) { FactoryBot.create(:org).id }

        it_behaves_like 'proxies the request', expected_private_flag: false
      end
    end

    context 'authenticated' do
      let(:headers) { authenticated_headers }

      context 'for a user' do
        let(:owner_type) { 'User' }
        let(:owner_id) { requested_user.id }

        before do
          # we need to use the v3 model to manipulate the preferences
          v3 = Travis::API::V3::Models::User.find requested_user.id
          v3.preferences.update(:private_insights_visibility, preference_value)
        end

        context 'themselves' do
          let(:requested_user) { user }

          context 'with private preference' do
            let(:preference_value) { 'private' }

            context 'requesting only public data' do
              let(:passed_private_flag) { false }
              it_behaves_like 'proxies the request', expected_private_flag: false
            end

            context 'requesting all data' do
              let(:passed_private_flag) { true }
              it_behaves_like 'proxies the request', expected_private_flag: true
            end
          end

          context 'with public preference' do
            let(:preference_value) { 'public' }

            context 'requesting only public data' do
              let(:passed_private_flag) { false }
              it_behaves_like 'proxies the request', expected_private_flag: false
            end

            context 'requesting all data' do
              let(:passed_private_flag) { true }
              it_behaves_like 'proxies the request', expected_private_flag: true
            end
          end
        end

        context 'a different one' do
          let(:requested_user) { FactoryBot.create(:user) }

          context 'with private preference' do
            let(:preference_value) { 'private' }
            it_behaves_like 'proxies the request', expected_private_flag: false
          end

          context 'with public preference' do
            let(:preference_value) { 'public' }

            context 'requesting only public data' do
              let(:passed_private_flag) { false }
              it_behaves_like 'proxies the request', expected_private_flag: false
            end

            context 'requesting all data' do
              let(:passed_private_flag) { true }
              it_behaves_like 'proxies the request', expected_private_flag: true
            end
          end
        end
      end

      context 'for an organization' do
        let(:owner_type) { 'Organization' }
        let(:owner_id) { requested_organization.id }

        before do
          # we need to use the v3 model to manipulate the preferences
          v3 = Travis::API::V3::Models::Organization.find requested_organization.id
          v3.preferences.update(:private_insights_visibility, preference_value)
        end

        context 'they belong to' do
          let(:requested_organization) { organization }

          before do
            organization.memberships.create!(user: user, role: role)
          end

          context 'as admin' do
            let(:role) { 'admin' }

            context 'with admins preference' do
              let(:preference_value) { 'admins' }

              context 'requesting only public data' do
                let(:passed_private_flag) { false }
                it_behaves_like 'proxies the request', expected_private_flag: false
              end

              context 'requesting all data' do
                let(:passed_private_flag) { true }
                it_behaves_like 'proxies the request', expected_private_flag: true
              end
            end

            context 'with members preference' do
              let(:preference_value) { 'members' }

              context 'requesting only public data' do
                let(:passed_private_flag) { false }
                it_behaves_like 'proxies the request', expected_private_flag: false
              end

              context 'requesting all data' do
                let(:passed_private_flag) { true }
                it_behaves_like 'proxies the request', expected_private_flag: true
              end
            end

            context 'with public preference' do
              let(:preference_value) { 'public' }

              context 'requesting only public data' do
                let(:passed_private_flag) { false }
                it_behaves_like 'proxies the request', expected_private_flag: false
              end

              context 'requesting all data' do
                let(:passed_private_flag) { true }
                it_behaves_like 'proxies the request', expected_private_flag: true
              end
            end
          end

          context 'as simple user' do
            let(:role) { 'member' }

            context 'with admins preference' do
              let(:preference_value) { 'admins' }
              it_behaves_like 'proxies the request', expected_private_flag: false
            end

            context 'with members preference' do
              let(:preference_value) { 'members' }

              context 'requesting only public data' do
                let(:passed_private_flag) { false }
                it_behaves_like 'proxies the request', expected_private_flag: false
              end

              context 'requesting all data' do
                let(:passed_private_flag) { true }
                it_behaves_like 'proxies the request', expected_private_flag: true
              end
            end

            context 'with public preference' do
              let(:preference_value) { 'public' }

              context 'requesting only public data' do
                let(:passed_private_flag) { false }
                it_behaves_like 'proxies the request', expected_private_flag: false
              end

              context 'requesting all data' do
                let(:passed_private_flag) { true }
                it_behaves_like 'proxies the request', expected_private_flag: true
              end
            end
          end
        end

        context 'a different one' do
          let(:requested_organization) { FactoryBot.create(:org) }

          context 'with admins preference' do
            let(:preference_value) { 'admins' }
            it_behaves_like 'proxies the request', expected_private_flag: false
          end

          context 'with members preference' do
            let(:preference_value) { 'members' }
            it_behaves_like 'proxies the request', expected_private_flag: false
          end

          context 'with public preference' do
            let(:preference_value) { 'public' }

            context 'requesting only public data' do
              let(:passed_private_flag) { false }
              it_behaves_like 'proxies the request', expected_private_flag: false
            end

            context 'requesting all data' do
              let(:passed_private_flag) { true }
              it_behaves_like 'proxies the request', expected_private_flag: true
            end
          end
        end
      end
    end
  end
end

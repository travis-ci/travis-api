describe Travis::API::V3::Services::Preference::ForOrganization, set_app: true do
  let(:organization) { Travis::API::V3::Models::Organization.create!(name: 'travis-ci') }
  let(:user) { Travis::API::V3::Models::User.create!(name: 'svenfuchs') }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }
  let(:preference_name) { 'private_insights_visibility' }
  let(:path) { "/v3/org/#{organization.id}/preference/#{preference_name}" }

  describe 'not authenticated' do
    let(:last_response) { get(path) }
    include_examples 'not authenticated'
  end

  describe 'authenticated' do
    let(:last_response) { get(path, {}, auth_headers) }

    describe 'organization does not exist' do
      let(:path) { "/v3/org/99999999/preference/#{preference_name}" }
      it { expect(last_response.status).to eq(404) }
    end

    describe 'user is not a member' do
      it { expect(last_response.status).to eq(404) }
      it { expect(parsed_body['error_message']).to include('insufficient access')}
    end

    describe 'user is a member' do
      before { organization.memberships.create!(user: user, role: role) }

      describe 'as a regular member' do
        let(:role) { 'member' }
        it { expect(last_response.status).to eq(404) }
        it { expect(parsed_body['error_message']).to include('insufficient access')}
      end

      describe 'as an admin' do
        let(:role) { 'admin' }

        example { expect(last_response.status).to eq(200) }

        describe 'no preferences have been set yet' do
          it 'returns the defaults' do
            expect(parsed_body).to eql_json(
              "@type" => "preference",
              "@href" => path,
              "@representation" => "standard",
              "name" => "private_insights_visibility",
              "value" => "admins"
            )
          end
        end

        describe 'some preference has been set' do
          before do
            organization.preferences.update(:private_insights_visibility, 'members')
          end

          it 'returns the set value merged with the defaults' do
            expect(parsed_body).to eql_json(
              "@type" => "preference",
              "@href" => path,
              "@representation" => "standard",
              "name" => "private_insights_visibility",
              "value" => "members"
            )
          end
        end

        describe 'preference name is mispelled' do
          let(:preference_name) { 'does-not-exist' }
          it { expect(last_response.status).to eq(404) }
        end
      end
    end
  end
end

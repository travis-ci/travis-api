describe Travis::API::V3::Services::Preference::Update, set_app: true do
  let(:github_oauth_token) { 'bar' }
  let(:user) { Travis::API::V3::Models::User.create!(name: 'svenfuchs', github_oauth_token: github_oauth_token) }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}", 'CONTENT_TYPE' => 'application/json' } }
  let(:params) { JSON.dump('preference.value' => preference_value) }

  example do
    expect(user.github_oauth_token).to eq github_oauth_token
  end

  describe 'for user' do
    let(:path) { "/v3/preference/build_emails" }
    let(:preference_value) { false }

    describe 'not authenticated' do
      let(:last_response) { patch(path) }
      include_examples 'not authenticated'

      it 'does not update the value' do
        expect { last_response }.to_not change { user.reload.preferences.build_emails }
      end
    end

    describe 'authenticated' do
      let(:last_response) { patch(path, params, headers) }

      it 'updates the value' do
        expect { last_response }.to change { user.reload.preferences.build_emails }.from(true).to(false)
      end

      it 'renders the updated value' do
        expect(last_response.status).to eq 200
        expect(parsed_body).to eql_json(
          "@type" => "preference",
          "@href" => "/v3/preference/build_emails",
          "@representation" => "standard",
          "name" => "build_emails",
          "value" => false
        )
      end
    end
  end

  describe 'for organization' do
    let(:organization) { Travis::API::V3::Models::Organization.create!(name: 'travis-ci') }
    let(:path) { "/v3/org/#{organization.id}/preference/private_insights_visibility" }
    let(:preference_value) { 'public' }

    describe 'not authenticated' do
      let(:last_response) { patch(path) }
      include_examples 'not authenticated'

      it 'does not update the value' do
        expect { last_response }.to_not change { organization.reload.preferences.private_insights_visibility }
      end
    end

    describe 'authenticated' do
      let(:last_response) { patch(path, params, headers) }

      describe 'organization does not exist' do
        let(:path) { "/v3/org/99999999/preference/private_insights_visibility" }
        it { expect(last_response.status).to eq(404) }
      end

      describe 'user is not a member' do
        it { expect(last_response.status).to eq(404) }
        it { expect(parsed_body['error_message']).to include('insufficient access')}

        it 'does not update the value' do
          expect { last_response }.to_not change { organization.reload.preferences.private_insights_visibility }
        end
      end

      describe 'user is a member' do
        before { organization.memberships.create!(user: user, role: role) }

        describe 'as a regular member' do
          let(:role) { 'member' }
          it { expect(last_response.status).to eq(404) }
          it { expect(parsed_body['error_message']).to include('insufficient access')}

          it 'does not update the value' do
            expect { last_response }.to_not change { organization.reload.preferences.private_insights_visibility }
          end
        end

        describe 'as an admin' do
          let(:role) { 'admin' }

          it 'updates the value' do
            expect { last_response }.to change { organization.reload.preferences.private_insights_visibility }.from('admins').to('public')
          end

          it 'renders the updated value' do
            expect(last_response.status).to eq(200)
            expect(parsed_body).to eql_json(
              "@type" => "preference",
              "@href" => path,
              "@representation" => "standard",
              "name" => "private_insights_visibility",
              "value" => "public"
            )
          end

          context 'the updated value is not valid' do
            let(:preference_value) { 'bananas' }

            it 'does not update the value' do
              expect { last_response }.to_not change { organization.reload.preferences.private_insights_visibility }
            end

            it 'renders an error' do
              expect(last_response.status).to eq(422)
              expect(parsed_body).to eql_json(
                "@type" => "error",
                "error_type" => "unprocessable_entity",
                "error_message" => "Private insights visibility 'bananas' is not allowed"
              )
            end
          end
        end
      end
    end
  end
end

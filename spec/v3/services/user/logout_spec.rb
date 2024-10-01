describe Travis::API::V3::Services::User::Logout, set_app: true do
  let(:user) { Travis::API::V3::Models::User.find_by_login('svenfuchs') }

  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                  }}
  before { stub_request(:post, %r((.+)/usage/stats)) }

  describe "logout user" do
    before  { get("/v3/logout", {}, headers)    }
    before  { get("/v3/user", {}, headers)      }
    example { expect(last_response).not_to be_ok }
  end
end

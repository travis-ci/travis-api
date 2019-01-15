describe 'Accounts', set_app: true do
  let(:user)     { User.first }
  let(:token)    { Travis::Api::App::AccessToken.create(user: user, app_id: -1).token }
  let(:headers)  { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }
  let(:response) { get '/accounts', { access_token: token }, headers }

  subject { JSON.parse(response.body) }

  it 'GET /accounts' do
    should eq(
      "accounts" => [
        {
          "id" => user.id,
          "name" => user.name,
          "login" => user.login,
          "type" => "user",
          "repos_count" => 0,
          "avatar_url" => nil
        }
      ]
    )
  end

  context 'on com' do
    before { Travis.config.host = 'travis-ci.com' }
    after  { Travis.config.host = 'travis-ci.org' }

    it 'GET /accounts includes subscription and education status' do
      expect(subject["accounts"][0]).to include(
        "subscribed" => false,
        "education" => false
      )
    end
  end
end

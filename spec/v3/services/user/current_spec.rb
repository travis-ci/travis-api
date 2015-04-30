require 'spec_helper'

describe Travis::API::V3::Services::User::Current do
  let(:user) { User.find_by_login('svenfuchs') }

  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                  }}

  describe "authenticated as user with access" do
    before  { get("/v3/user", {}, headers)     }
    example { expect(last_response).to be_ok   }
    example { expect(JSON.load(body)).to be == {
      "@type"        => "user",
      "@href"        => "/v3/user/#{user.id}",
      "@permissions" => {"read"=>true, "sync"=>true},
      "id"           => user.id,
      "login"        => "svenfuchs",
      "name"         =>"Sven Fuchs",
      "github_id"    => user.github_id,
      "avatar_url"   => "https://0.gravatar.com/avatar/07fb84848e68b96b69022d333ca8a3e2",
      "is_syncing"   => user.is_syncing,
      "synced_at"    => user.synced_at
    }}
  end
end
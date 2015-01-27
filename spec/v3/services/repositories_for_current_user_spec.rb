require 'spec_helper'

describe Travis::API::V3::Services::FindRepository do
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }

  describe "private repository, private API, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/repos", {}, headers)                                     }
    before        { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(JSON.load(body)).to be == {
      "@type"             => "repositories",
      "repositories"      => [{
        "@type"           => "repository",
        "id"              =>  repo.id,
        "name"            =>  "minimal",
        "slug"            =>  "svenfuchs/minimal",
        "description"     => nil,
        "github_language" => nil,
        "private"         => true,
        "owner"           => {
          "@type"         => "user",
          "id"            => repo.owner_id,
          "login"         => "svenfuchs" },
        "last_build"      => {
          "@type"         => "build",
          "id"            => repo.last_build_id,
          "number"        => "2",
          "state"         => "passed",
          "duration"      => nil,
          "started_at"    => "2010-11-12T12:30:00Z",
          "finished_at"   => "2010-11-12T12:30:20Z"}}]
    }}
  end
end
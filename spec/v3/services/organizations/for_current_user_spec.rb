require 'spec_helper'

describe Travis::API::V3::Services::Organizations::ForCurrentUser do
  let(:repo) { Repository.by_slug('svenfuchs/minimal').first }

  let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
  before        { Permission.create(repository: repo, user: repo.owner, pull: true) }
  before        { repo.update_attribute(:private, true)                             }
  after         { repo.update_attribute(:private, false)                            }

  let(:org) { Organization.new(login: 'example-org')   }
  before    { org.save!                                }
  before    { org.memberships.create(user: repo.owner) }
  after     { org.delete                               }

  describe "authenticated as user with access" do
    before  { get("/v3/orgs", {}, headers)     }
    example { expect(last_response).to be_ok   }
    example { expect(JSON.load(body)).to be == {
      "@type"         => "organizations",
      "@href"         => "/v3/orgs",
      "organizations" => [{
        "@type"       => "organization",
        "@href"       => "/v3/org/#{org.id}",
        "id"          => org.id,
        "login"       => "example-org",
        "name"        => nil,
        "github_id"   => nil,
        "avatar_url"  => nil
      }]
    }}
  end
end
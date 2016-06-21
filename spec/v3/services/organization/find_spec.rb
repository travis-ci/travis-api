describe Travis::API::V3::Services::Organization::Find, set_app: true do
  let(:org) { Travis::API::V3::Models::Organization.new(login: 'example-org') }
  before    { org.save!                              }
  after     { org.delete                             }

  describe 'existing org, public api' do
    before  { get("/v3/org/#{org.id}")       }
    example { expect(last_response).to be_ok }
    example { expect(JSON.load(body)).to be == {
      "@type"            => "organization",
      "@href"            => "/v3/org/#{org.id}",
      "@representation"  => "standard",
      "@permissions"     => { "read"=>true, "sync"=>false },
      "id"               => org.id,
      "login"            => "example-org",
      "name"             => nil,
      "github_id"        => nil,
      "avatar_url"       => nil
    }}
  end

  describe 'existing org, private api' do
    before  { Travis.config.private_api = true      }
    before  { get("/v3/org/#{org.id}")              }
    after   { Travis.config.private_api = false     }
    example { expect(last_response).to be_not_found }
    example { expect(JSON.load(body)).to be ==      {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" =>"organization not found (or insufficient access)",
      "resource_type" => "organization"
    }}
  end
end

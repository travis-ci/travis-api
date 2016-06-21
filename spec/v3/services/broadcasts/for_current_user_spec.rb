describe Travis::API::V3::Services::Broadcasts::ForCurrentUser, set_app: true do
  let(:repo)    { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}

  before        { Travis::API::V3::Models::Permission.create(user: repo.owner, pull: true) }
  before        { repo.update_attribute(:private, true)                             }
  after         { repo.update_attribute(:private, false)                            }

  let(:org) { Travis::API::V3::Models::Organization.new(login: 'example-org')   }
  before    { org.save!                                }
  before    { org.memberships.create(user: repo.owner) }
  after     { org.delete                               }

  before    { Travis::API::V3::Models::Broadcast.create(recipient_id: repo.id, recipient_type: "Repository", message: "Repository broadcast!", created_at: "2010-11-12T13:00:00Z", updated_at: "2010-11-12T13:00:00Z") }
  before    { Travis::API::V3::Models::Broadcast.create(recipient_id: org.id, recipient_type: "Organization", message: "Organization broadcast!", created_at: "2010-11-12T13:00:00Z", updated_at: "2010-11-12T13:00:00Z") }
  before    { Travis::API::V3::Models::Broadcast.create(recipient_id: repo.owner_id, recipient_type: "User", message: "User broadcast!", created_at: "2010-11-12T13:00:00Z", updated_at: "2010-11-12T13:00:00Z") }
  before    { Travis::API::V3::Models::Broadcast.create(recipient_id: nil, recipient_type: nil, message: "Global broadcast!", created_at: "2010-11-12T13:00:00Z", updated_at: "2010-11-12T13:00:00Z") }
  let(:broadcasts){ Travis::API::V3::Models::Broadcast.where(recipient_id: [repo.id, org.id, repo.owner_id, nil]) }


  describe "only active broadcasts" do
    before  { get("/v3/broadcasts", {}, headers) }
    example { expect(last_response).to be_ok   }
    example { expect(JSON.load(body)).to be == {
      "@type"            => "broadcasts",
      "@href"            => "/v3/broadcasts",
      "@representation"  => "standard",
      "broadcasts"       => []
    }}
  end

  describe "only inactive broadcasts" do
    let(:broadcast) { broadcasts.first }
    before  { get("/v3/broadcasts?broadcast.active=false", {}, headers) }
    example { expect(last_response).to be_ok   }
    example { expect(JSON.load(body)["broadcasts"].first).to be == {
      "@type"            => "broadcast",
      "@representation"  => "standard",
      "id"               => broadcast.id,
      "message"          => broadcast.message,
      "created_at"       => "2010-11-12T13:00:00Z",
      "category"         => nil,
      "active"           => false,
      "recipient"        => {
        "@type"          => "repository",
        "@href"          => "/v3/repo/#{repo.id}",
        "@representation"=> "minimal",
        "id"             => repo.id,
        "name"           => repo.name,
        "slug"           => repo.slug,
      }
    }}
  end
end

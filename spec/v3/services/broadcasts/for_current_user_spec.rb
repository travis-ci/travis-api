require 'spec_helper'

describe Travis::API::V3::Services::Broadcasts::ForCurrentUser do
  let(:repo)      { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  # let(:user)      { Travis::API::V3::Models::User.where(login: 'svenfuchs') }

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


  describe "authenticated as user with access" do
    before  { get("/v3/broadcasts", {}, headers)     }
    example { expect(last_response).to be_ok   }
    example { expect(JSON.load(body)).to be == {
      "@type"            => "broadcasts",
      "@href"            => "/v3/broadcasts",
      "@representation"  => "standard",
      "broadcasts"       => [{
        "@type"          => "broadcast",
        "@representation"=>"standard",
        "id"             => broadcasts[0].id,
        "recipient_id"   => broadcasts[0].recipient_id,
        "recipient_type" => broadcasts[0].recipient_type,
        "category"       => broadcasts[0].category,
        "kind"           => nil,
        "message"        => broadcasts[0].message,
        "expired"        => nil,
        "created_at"     => "2010-11-12T13:00:00Z",
        "updated_at"     => "2010-11-12T13:00:00Z" },
        {
        "@type"          => "broadcast",
        "@representation"=> "standard",
        "id"             => broadcasts[1].id,
        "recipient_id"   => broadcasts[1].recipient_id,
        "recipient_type" => broadcasts[1].recipient_type,
        "category"       => broadcasts[1].category,
        "kind"           => nil,
        "message"        => broadcasts[1].message,
        "expired"        => nil,
        "created_at"     => "2010-11-12T13:00:00Z",
        "updated_at"     => "2010-11-12T13:00:00Z"},
        {
        "@type"          => "broadcast",
        "@representation"=> "standard",
        "id"             => broadcasts[2].id,
        "recipient_id"   => broadcasts[2].recipient_id,
        "recipient_type" => broadcasts[2].recipient_type,
        "category"       => broadcasts[2].category,
        "kind"           => nil,
        "message"        => broadcasts[2].message,
        "expired"        => nil,
        "created_at"     => "2010-11-12T13:00:00Z",
        "updated_at"     => "2010-11-12T13:00:00Z"},
        {
        "@type"          => "broadcast",
        "@representation"=> "standard",
        "id"             => broadcasts[3].id,
        "recipient_id"   => broadcasts[3].recipient_id,
        "recipient_type" => broadcasts[3].recipient_type,
        "category"       => broadcasts[3].category,
        "kind"           => nil,
        "message"        => broadcasts[3].message,
        "expired"        => nil,
        "created_at"     => "2010-11-12T13:00:00Z",
        "updated_at"     => "2010-11-12T13:00:00Z"}]
    }}
  end
end

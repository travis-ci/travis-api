require 'spec_helper'

describe Travis::API::V3::Services::Broadcasts::ForCurrentUser do
  let(:user)      { Travis::API::V3::Models::User.where(login: 'svenfuchs').first }
  let(:broadcast) { Travis::API::V3::Models::Broadcast.where(recipient_id: user.id) }

  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
  before        { Travis::API::V3::Models::Permission.create(user: user, pull: true) }
  # before        { Travis::API::V3::Models::Broadcast.create(recipient_id: repo.id, recipient_type: "Organization", message: "This is a test!") }
  # before        { repo.update_attribute(:private, true)                             }
  # after         { repo.update_attribute(:private, false)                            }

  # let(:org) { Travis::API::V3::Models::Organization.new(login: 'example-org')   }
  # before    { org.save!                                }
  # before    { org.memberships.create(user: user.login) }
  # after     { org.delete                               }

  describe "authenticated as user with access" do
    before  { get("/v3/broadcasts", {}, headers)     }
    example { expect(last_response).to be_ok   }
    example { expect(JSON.load(body)).to be == {
      "@type"             => "broadcasts",
      "@href"             => "/v3/broadcasts",
      "@representation"    => "standard",
      "broadcasts"     => [{
        "@type"           => "broadcast",
        "@representation" => "standard",
        "@permissions"    => { "read"=>true, "sync"=>true },
        "id"              => broadcasts[0].id,
        "recipient_id"    => broadcasts[0].recipient_id,
        "recipient_type"  => broadcasts[0].recipient_type,
        "kind"            => broadcast[0].kind,
        "message"         => broadcast[0].message,
        "expired"         => nil,
        "created_at"      => "2015-09-10T11:05:21Z",
        "updated_at"      => "2015-09-10T11:05:21Z"
      }]
    }}
  end
end

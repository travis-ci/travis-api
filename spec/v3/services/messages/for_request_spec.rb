describe Travis::API::V3::Services::Messages::ForRequest, set_app: true do

  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:request) { repo.requests.first }
  let!(:message) { Travis::API::V3::Models::Message.create!(level: 'info', subject_id: request.id, subject_type: 'Request')}
  let!(:message_2) { Travis::API::V3::Models::Message.create!(level: 'error', subject_id: request.id, subject_type: 'Request')}

  describe "retrieve request messages on a public repository" do
    before     { get("/v3/repo/#{repo.id}/request/#{request.id}/messages")     }
    example    { expect(last_response).to be_ok }
    example    { expect(JSON.load(body).to_s).to include(
                  "@type",
                  "messages",
                  "/v3/repo/#{repo.id}/request/#{request.id}/messages",
                  "id",
                  "level",
                  "key",
                  "code",
                  "args",
                  "representation",
                  "@pagination")
    }
    example 'ordered messages by level' do
      expect(JSON.load(body)['messages'].map { |m| m['id'] }).to eq [message_2.id, message.id]
    end
  end

  describe "retrieve request messages on private repository, private API, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/repo/#{repo.id}/request/#{request.id}/messages", {}, headers)                             }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(JSON.load(body).to_s).to include( 
                    "@type",
                    "messages",
                    "/v3/repo/#{repo.id}/request/#{request.id}/messages",
                    "id",
                    "level",
                    "key",
                    "code",
                    "args",
                    "representation",
                    "@pagination"
                      )
    }

  end

  describe 'raise not_found when request id is bad' do
    before  { get("/v3/repo/#{repo.id}/request/undefined/messages")     }
    example { expect(last_response).to be_not_found }
  end
end

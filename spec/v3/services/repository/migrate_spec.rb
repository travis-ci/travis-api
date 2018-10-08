describe Travis::API::V3::Services::Repository::Migrate, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }

  before do
    repo.update_attributes!(active: true)
  end

  describe "not authenticated" do
    before  { post("/v3/repo/#{repo.id}/migrate")      }
    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    }}
  end

  describe "missing repo, authenticated" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { post("/v3/repo/9999999999/migrate", {}, headers)                 }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "existing repository, no push access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { post("/v3/repo/#{repo.id}/migrate", {}, headers)                 }

    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "error_type",
      "insufficient_access",
      "error_message",
      "operation requires migrate access to repository",
      "resource_type",
      "repository",
      "permission",
      "migrate")
    }
  end

  describe "private repository, no access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { repo.update_attribute(:private, true)                             }
    before        { post("/v3/repo/#{repo.id}/migrate", {}, headers)                  }
    after         { repo.update_attribute(:private, false)                            }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe 'existing repository, wrong access' do
    let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
    before { stub_request(:any, %r(api.github.com/repos/#{repo.slug}/hooks(/\d+)?)) }
    before { post("/v3/repo/#{repo.id}/migrate", {}, headers) }

    example 'is success' do
      expect(last_response.status).to eq 403
      expect(JSON.load(body)).to include(
        '@type' => 'error',
        'error_type' => 'admin_access_required'
      )
    end
  end

  describe "existing repository, admin access" do
    let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}

    before do
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, admin: true, push: true)
    end

    example 'it returns a JSON struct with the repository in question' do
      Travis::Kafka.expects(:deliver_message).with(
        {
          :topic => 'essential.repository.migrate',
          :msg   => {
            :data     => { :owner_name => 'svenfuchs', :name => 'minimal' },
            :metadata => { :force_reimport => false },
          }
        }
      ).returns(nil)

      Travis.logger.expects(:info).returns(nil)

      post("/v3/repo/#{repo.id}/migrate", {}, headers)

      expect(last_response.status).to eq 200
      expect(JSON.load(body)).to include(
        '@type' => 'repository',
      )
    end

    context "when Kafka errors" do
      example "it logs the error and raise an error"  do
        Travis::Kafka.expects(:deliver_message).raises(Kafka::Error)
        Logger.any_instance.expects(:error).returns(nil)

        expect {
          post("/v3/repo/#{repo.id}/migrate", {}, headers)
        }.to raise_error(Kafka::Error)

      end
    end
  end
end

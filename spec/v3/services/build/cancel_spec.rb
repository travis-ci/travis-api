require 'spec_helper'

describe Travis::API::V3::Services::Build::Cancel do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build) { repo.builds.first }
  let(:sidekiq_payload) { JSON.load(Sidekiq::Client.last['args'].last[:payload]) }
  let(:sidekiq_params) { Sidekiq::Client.last['args'].last.deep_symbolize_keys }

  before do
    Travis::Features.stubs(:owner_active?).returns(true)
    @original_sidekiq = Sidekiq::Client
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = []
  end

  after do
    Sidekiq.send(:remove_const, :Client) # to avoid a warning
    Sidekiq::Client = @original_sidekiq
  end

  describe "not authenticated" do
    before  { post("/v3/build/#{build.id}/cancel")      }
    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    }}
  end

  describe "missing build, authenticated" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { post("/v3/build/9999999999/cancel", {}, headers)                 }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "build not found (or insufficient access)",
      "resource_type" => "build"
    }}
  end

  describe "existing repository, no push access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { post("/v3/build/#{build.id}/cancel", {}, headers)                 }

    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "error_type",
      "insufficient_access",
      "error_message",
      "operation requires cancel access to build",
      "resource_type",
      "build",
      "permission",
      "cancel")
    }
  end

  describe "private repository, no access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { repo.update_attribute(:private, true)                             }
    before        { post("/v3/build/#{build.id}/cancel", {}, headers)                 }
    after         { repo.update_attribute(:private, false)                            }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "build not found (or insufficient access)",
      "resource_type" => "build"
    }}
  end

  describe "existing repository, push access" do
    let(:params)  {{}}
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1)                          }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                                                 }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
    before        { post("/v3/build/#{build.id}/cancel", params, headers)                                      }

    example { expect(last_response.status).to be == 202 }
    example { expect(JSON.load(body).to_s).to include(
      "@type",
      "build",
      "@href",
      "@representation",
      "minimal",
      "cancel",
      "id",
      "state_change")
    }

    example { expect(sidekiq_payload).to be == {
      "build"    => {
        "id"     => "#{build.id}",
        "user_id"=> repo.owner_id,
        "source" => "api"}
    }}

    example { expect(Sidekiq::Client.last['queue']).to be == 'build_cancellations'                }
    example { expect(Sidekiq::Client.last['class']).to be == 'Travis::Sidekiq::BuildCancellation' }

    describe "setting id has no effect" do
      let(:params) {{ id: 42 }}
      example { expect(sidekiq_payload).to be == {
        "build"    => {
          "id"     => "#{build.id}",
          "user_id"=> repo.owner_id,
          "source" => "api"}
      }}
    end
  end


  # describe "existing repository, application with full access" do
  #   let(:app_name)   { 'travis-example'                                                           }
  #   let(:app_secret) { '12345678'                                                                 }
  #   let(:sign_opts)  { "a=#{app_name}"                                                            }
  #   let(:signature)  { OpenSSL::HMAC.hexdigest('sha256', app_secret, sign_opts)                   }
  #   let(:headers)    {{ 'HTTP_AUTHORIZATION' => "signature #{sign_opts}:#{signature}"            }}
  #   before { Travis.config.applications = { app_name => { full_access: true, secret: app_secret }}}
  #   before { post("/v3/build/#{build.id}/cancel", params, headers)                                }
  #
  #   describe 'without setting user' do
  #     let(:params) {{}}
  #     example { expect(last_response.status).to be == 400 }
  #     example { expect(JSON.load(body)).to      be ==     {
  #       "@type"         => "error",
  #       "error_type"    => "wrong_params",
  #       "error_message" => "missing user"
  #     }}
  #   end

    # describe 'setting user' do
    #   let(:params) {{ user: { id: repo.owner.id } }}
    #   example { expect(last_response.status).to be == 202 }
    #   example { expect(sidekiq_payload).to be == {
    #     repository: { id: repo.id, owner_name: 'svenfuchs', name: 'minimal' },
    #     user:       { id: repo.owner.id },
    #     message:    nil,
    #     branch:     'master',
    #     config:     {}
    #   }}
    # end
  # end
end

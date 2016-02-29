require 'spec_helper'

describe Travis::API::V3::Services::Overview::Streak do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }

  describe "fetching steak data on a public repository" do
    before  { get("/v3/repo/#{repo.id}/overview/streak") }
    example { expect(last_response).to be_ok             }
  end

  describe "fetching streak from non-existing repo" do
    before  { get("/v3/repo/1231987129387218/overview/streak") }
    example { expect(last_response).to be_not_found            }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "streak on public repository" do
    before  {
      Travis::API::V3::Models::Build.where(repository_id: repo.id).each do |build| build.destroy end
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'push', created_at: DateTime.now - 5, state: 'passed',   branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'cron', created_at: DateTime.now - 4, state: 'canceled', branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'push', created_at: DateTime.now - 2, state: 'passed',   branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'push', created_at: DateTime.now    , state: 'passed',   branch_name: repo.default_branch.name)
      get("/v3/repo/#{repo.id}/overview/streak") }
    example { expect(last_response).to be_ok     }
    example { expect(parsed_body).to be == {
      "@type"           => "overview",
      "@href"           => "/v3/repo/#{repo.id}/overview/streak",
      "@representation" => "standard",
      "streak"          => {
          'days'   => 2,
          'builds' => 2
      }
    }}
  end

  describe "streak on public empty repository" do
    before  {
      Travis::API::V3::Models::Build.where(repository_id: repo.id).each do |build| build.destroy end
      get("/v3/repo/#{repo.id}/overview/streak") }
    example { expect(last_response).to be_ok     }
    example { expect(parsed_body).to be == {
      "@type"           => "overview",
      "@href"           => "/v3/repo/#{repo.id}/overview/streak",
      "@representation" => "standard",
      "streak"          => {
          'days'   => 0,
          'builds' => 0
      }
    }}
  end

  describe "streak on public never failing repository" do
    before  {
      Travis::API::V3::Models::Build.where(repository_id: repo.id).each do |build| build.destroy end
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'push', created_at: DateTime.now - 15, state: 'passed', branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'cron', created_at: DateTime.now - 5,  state: 'passed', branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'push', created_at: DateTime.now,      state: 'passed', branch_name: repo.default_branch.name)
      get("/v3/repo/#{repo.id}/overview/streak") }
    example { expect(last_response).to be_ok     }
    example { expect(parsed_body).to be == {
      "@type"           => "overview",
      "@href"           => "/v3/repo/#{repo.id}/overview/streak",
      "@representation" => "standard",
      "streak"          => {
          'days'   => 15,
          'builds' => 2
      }
    }}
  end

  describe "days of future-past (streak when first passed build is in future)" do
    before  {
      Travis::API::V3::Models::Build.where(repository_id: repo.id).each do |build| build.destroy end
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'push', created_at: DateTime.now - 5, state: 'failed', branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'push', created_at: DateTime.now,     state: 'failed', branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'push', created_at: DateTime.now + 5, state: 'passed', branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'push', created_at: DateTime.now + 6, state: 'passed', branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'push', created_at: DateTime.now + 7, state: 'passed', branch_name: repo.default_branch.name)
      get("/v3/repo/#{repo.id}/overview/streak") }
    example { expect(last_response).to be_ok     }
    example { expect(parsed_body).to be == {
      "@type"           => "overview",
      "@href"           => "/v3/repo/#{repo.id}/overview/streak",
      "@representation" => "standard",
      "streak"          => {
          'days'   => -5,
          'builds' => 3
      }
    }}
  end

  describe "private repository, not authenticated" do
    before  { repo.update_attribute(:private, true)      }
    before  { get("/v3/repo/#{repo.id}/overview/streak") }
    before  { repo.update_attribute(:private, false)     }
    example { expect(last_response).to be_not_found      }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "private repository, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"}                        }
    before        { Travis::API::V3::Models::Build.where(repository_id: repo).each do |build| build.destroy end
                    Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/repo/#{repo.id}/overview/streak", {}, headers)           }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(parsed_body).to be == {
      "@type"           => "overview",
      "@href"           => "/v3/repo/#{repo.id}/overview/streak",
      "@representation" => "standard",
      "streak"          => {
          'days'   => 0,
          'builds' => 0
      }
    }}
  end
end

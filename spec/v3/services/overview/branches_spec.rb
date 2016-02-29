require 'spec_helper'

describe Travis::API::V3::Services::Overview::Branches do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:branch1) { repo.default_branch }
  let(:branch2) { Travis::API::V3::Models::Branch.create(repository_id: repo.id, name: 'new_branch') }

  describe "fetching overview/branches on a public repository" do
    before  { get("/v3/repo/#{repo.id}/overview/branches") }
    example { expect(last_response).to be_ok               }
  end

  describe "fetching overview/branches from non-existing repo" do
    before  { get("/v3/repo/1231987129387218/overview/branches") }
    example { expect(last_response).to be_not_found              }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "overview/branches on public repository" do
    before  {
      Travis::API::V3::Models::Build.where(repository_id: repo.id).each do |build| build.destroy end

      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'push', state: 'passed',  branch_name: branch1.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'push', state: 'failed',  branch_name: branch1.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'push', state: 'errored', branch_name: branch1.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'push', state: 'passed',  branch_name: branch2.name)

      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'pull_request', state: 'passed', branch_name: branch1.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'pull_request', state: 'failed', branch_name: branch2.name)

      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'cron', state: 'passed', branch_name: branch1.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'cron', state: 'failed', branch_name: branch2.name)
      get("/v3/repo/#{repo.id}/overview/branches") }
    example { expect(last_response).to be_ok       }
    example { expect(parsed_body).to be == {
      "@type"           => "overview",
      "@href"           => "/v3/repo/#{repo.id}/overview/branches",
      "@representation" => "standard",
      "branches"        => {
        branch1.name => 0.5,
        branch2.name => 0.5
      }
    }}
  end

  describe "overview/branches only counts builds created in the last 30 days" do
    before  {
      Travis::API::V3::Models::Build.where(repository_id: repo.id).each do |build| build.destroy end

      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'push', state: 'passed',  branch_name: branch1.name, created_at: Date.today - 30)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'push', state: 'failed',  branch_name: branch1.name, created_at: Date.today - 30)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'cron', state: 'errored', branch_name: branch1.name, created_at: Date.today - 30)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, event_type: 'push', state: 'passed',  branch_name: branch2.name, created_at: Date.today - 30)
      get("/v3/repo/#{repo.id}/overview/branches") }
    example { expect(last_response).to be_ok       }
    example { expect(parsed_body).to be == {
      "@type"           => "overview",
      "@href"           => "/v3/repo/#{repo.id}/overview/branches",
      "@representation" => "standard",
      "branches"        => {}
    }}
  end

  describe "overview/branches on public repository with no builds" do
    before  {
      Travis::API::V3::Models::Build.where(repository_id: repo.id).each do |build| build.destroy end

      get("/v3/repo/#{repo.id}/overview/branches") }
    example { expect(last_response).to be_ok       }
    example { expect(parsed_body).to be == {
      "@type"           => "overview",
      "@href"           => "/v3/repo/#{repo.id}/overview/branches",
      "@representation" => "standard",
      "branches"        => {}
    }}
  end

  describe "private repository, not authenticated" do
    before  { repo.update_attribute(:private, true)        }
    before  { get("/v3/repo/#{repo.id}/overview/branches") }
    before  { repo.update_attribute(:private, false)       }
    example { expect(last_response).to be_not_found        }
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
    before        { get("/v3/repo/#{repo.id}/overview/branches", {}, headers)         }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(parsed_body).to be == {
      "@type"           => "overview",
      "@href"           => "/v3/repo/#{repo.id}/overview/branches",
      "@representation" => "standard",
      "branches"        => {}
    }}
  end
end

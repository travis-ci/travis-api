require 'spec_helper'

describe Travis::API::V3::Services::Overview::History do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }

  describe "fetching history data on a public repository" do
    before  { get("/v3/repo/#{repo.id}/overview/history") }
    example { expect(last_response).to be_ok             }
  end

  describe "fetching history from non-existing repo" do
    before  { get("/v3/repo/1231987129387218/overview/history") }
    example { expect(last_response).to be_not_found            }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "history on public repository" do
    before  {
      finished = DateTime.now
      started = finished - 1
      Travis::API::V3::Models::Build.where(repository_id: repo.id).each do |build| build.destroy end
      Travis::API::V3::Models::Build.create(repository_id: repo.id, created_at: DateTime.now - 5, started_at: started, finished_at: finished, branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, created_at: DateTime.now - 4, started_at: started, finished_at: finished, branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, created_at: DateTime.now - 2, started_at: started, finished_at: finished, branch_name: repo.default_branch.name)
      Travis::API::V3::Models::Build.create(repository_id: repo.id, created_at: DateTime.now    , started_at: started, finished_at: finished, branch_name: repo.default_branch.name)
      get("/v3/repo/#{repo.id}/overview/history") }
    example { expect(last_response).to be_ok     }
    example { expect(parsed_body).to be == {
      "@type"           => "overview",
      "@href"           => "/v3/repo/#{repo.id}/overview/history",
      "@representation" => "standard",
      "history"         => {
        "builds"  => 4,
        "seconds" => 345600
      }
    }}
  end

  describe "private repository, not authenticated" do
    before  { repo.update_attribute(:private, true)             }
    before  { get("/v3/repo/#{repo.id}/overview/history") }
    before  { repo.update_attribute(:private, false)            }
    example { expect(last_response).to be_not_found             }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "empty private repository, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1)                              }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"}                                                     }
    before        { Travis::API::V3::Models::Build.where(repository_id: repo.id).each do |build| build.destroy end }
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true)     }
    before        { repo.update_attribute(:private, true)                                                          }
    before        { get("/v3/repo/#{repo.id}/overview/history", {}, headers)                                 }
    after         { repo.update_attribute(:private, false)                                                         }
    example       { expect(last_response).to be_ok                                                                 }
    example       { expect(parsed_body).to be == {
      "@type"                => "overview",
      "@href"                => "/v3/repo/#{repo.id}/overview/history",
      "@representation"      => "standard",
      "history"         => {
        "builds"  => 0,
        "seconds" => 0
      }
    }}
  end
end

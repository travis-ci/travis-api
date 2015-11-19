require 'spec_helper'

describe Travis::API::V3::Services::Cron::Find do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:branch) { Travis::API::V3::Models::Branch.where(repository_id: repo).first }
  let(:cron)  { Travis::API::V3::Models::Cron.create(branch: branch) }
  let(:parsed_body) { JSON.load(body) }

  describe "fetching a cron job by id" do
    before     { get("/v3/cron/#{cron.id}")     }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to be == {
        "@type"               => "cron",
        "@href"               => "/v3/cron/#{cron.id}",
        "@representation"     => "standard",
        "@permissions"        => {
            "read"            => true,
            "delete"          => false },
        "id"                  => cron.id,
        "repository"          => {
            "@type"           => "repository",
            "@href"           => "/v3/repo/#{repo.id}",
            "@representation" => "minimal",
            "id"              => repo.id,
            "name"            => "minimal",
            "slug"            => "svenfuchs/minimal" },
        "branch"              => {
            "@type"           => "branch",
            "@href"           => "/v3/repo/#{repo.id}/branch/#{branch.name}",
            "@representation" => "minimal",
            "name"            => branch.name },
        "hour"                => nil,
        "mon"                 => false,
        "tue"                 => false,
        "wed"                 => false,
        "thu"                 => false,
        "fri"                 => false,
        "sat"                 => false,
        "sun"                 => false,
        "disable_by_push"     => true
    }}
  end

  describe "fetching a non-existing cron job by id" do
    before     { get("/v3/cron/999999999999999")     }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "cron not found (or insufficient access)",
      "resource_type" => "cron"
    }}
  end

  describe "private cron, not authenticated" do
    before  { repo.update_attribute(:private, true)  }
    before  { get("/v3/cron/#{cron.id}")             }
    after   { repo.update_attribute(:private, false) }
    example { expect(last_response).to be_not_found  }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "cron not found (or insufficient access)",
      "resource_type" => "cron"
    }}
  end

  describe "private cron, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/cron/#{cron.id}", {}, headers)                           }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(parsed_body).to be == {
      "@type"               => "cron",
      "@href"               => "/v3/cron/#{cron.id}",
      "@representation"     => "standard",
      "@permissions"        => {
          "read"            => true,
          "delete"          => false },
      "id"                  => cron.id,
      "repository"          => {
          "@type"           => "repository",
          "@href"           => "/v3/repo/#{repo.id}",
          "@representation" => "minimal",
          "id"              => repo.id,
          "name"            => "minimal",
          "slug"            => "svenfuchs/minimal" },
      "branch"              => {
          "@type"           => "branch",
          "@href"           => "/v3/repo/#{repo.id}/branch/#{branch.name}",
          "@representation" => "minimal",
          "name"            => branch.name },
      "hour"                => nil,
      "mon"                 => false,
      "tue"                 => false,
      "wed"                 => false,
      "thu"                 => false,
      "fri"                 => false,
      "sat"                 => false,
      "sun"                 => false,
      "disable_by_push"     => true
    }}
  end

end

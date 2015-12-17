require 'spec_helper'

describe Travis::API::V3::Services::Cron::Delete do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:branch) { Travis::API::V3::Models::Branch.where(repository_id: repo).first }
  let(:cron)  { Travis::API::V3::Models::Cron.create(branch: branch) }
  let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
  let(:parsed_body) { JSON.load(body) }

  describe "deleting a cron job by id" do
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true) }
    before     { post("/v3/cron/#{cron.id}/delete", {}, headers) }
    example    { expect(last_response).to be_ok }
    example    { expect(Travis::API::V3::Models::Cron.where(id: cron.id)).to be_empty }
    example    { expect(parsed_body).to be == {
        "@type"               => "cron",
        "@href"               => "/v3/cron/#{cron.id}",
        "@representation"     => "standard",
        "@permissions"        => {
            "read"            => true,
            "delete"          => true },
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

  describe "try deleting a cron job without login" do
    before     { post("/v3/cron/#{cron.id}/delete") }
    example    { expect(Travis::API::V3::Models::Cron.where(id: cron.id)).to exist }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    }}
  end

  describe "try deleting a cron job with a user without permissions" do
    before     { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: false) }
    before     { post("/v3/cron/#{cron.id}/delete", {}, headers) }
    example    { expect(Travis::API::V3::Models::Cron.where(id: cron.id)).to exist }
    example    { expect(parsed_body).to be == {
        "@type"               => "error",
        "error_type"          => "insufficient_access",
        "error_message"       => "operation requires delete access to cron",
        "resource_type"       => "cron",
        "permission"          => "delete",
        "cron"                => {
            "@type"           => "cron",
            "@href"           => "/cron/#{cron.id}", # should be /v3/cron/#{cron.id}
            "@representation" => "minimal",
            "id"              => cron.id }
    }}
  end

  describe "try deleting a non-existing cron job" do
    before  { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: false) }
    before  { post("/v3/cron/999999999999999/delete", {}, headers) }
    example { expect(parsed_body).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "cron not found (or insufficient access)",
      "resource_type" => "cron"
    }}
  end

end

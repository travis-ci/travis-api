describe Travis::API::V3::Services::Branches::Find, set_app: true do
  let(:repo)   { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:branch) { Travis::API::V3::Models::Branch.where(repository_id: repo.id).first }
  let(:build)  { branch.last_build }

  let(:jobs)   { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:parsed_body) { JSON.load(body) }

  describe "fetching branches on a public repository by slug" do
    before  { get("/v3/repo/svenfuchs%2Fminimal/branches")     }
    example { expect(last_response).to be_ok }
  end

  describe "fetching branches on a non-existing repository by slug" do
    before  { get("/v3/repo/svenfuchs%2Fminimal1/branches")     }
    example { expect(last_response).to be_not_found }
    example { expect(parsed_body).to eql_json({
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    })}
  end

  describe "builds on public repository" do
    before     { get("/v3/repo/#{repo.id}/branches?limit=1") }
    example    { expect(last_response).to be_ok }
    example    { expect(parsed_body).to eql_json({
      "@type"              => "branches",
      "@href"              => "/v3/repo/#{repo.id}/branches?limit=1",
      "@representation"    => "standard",
      "@pagination"        => {
        "limit"            => 1,
        "offset"           => 0,
        "count"            => 1,
        "is_first"         => true,
        "is_last"          => true,
        "next"             => nil,
        "prev"             => nil,
        "first"            => {
          "@href"          => "/v3/repo/#{repo.id}/branches?limit=1",
          "offset"         => 0,
          "limit"          => 1 },
        "last"             => {
          "@href"          => "/v3/repo/#{repo.id}/branches?limit=1",
          "offset"         => 0,
          "limit"          => 1 }},
      "branches"           => [{
        "@type"            => "branch",
        "@href"            => "/v3/repo/#{repo.id}/branch/master",
        "@representation"  => "standard",
        "name"             => "master",
        "default_branch"   => true,
        "exists_on_github" => true,
        "repository"       => {
          "@type"          => "repository",
          "@href"          => "/v3/repo/#{repo.id}",
          "@representation"=> "minimal",
          "id"             => repo.id,
          "name"           => "minimal",
          "slug"           => "svenfuchs/minimal"},
        "last_build"       => {
          "@type"          => "build",
          "@href"          => "/v3/build/#{build.id}",
          "@representation"=> "minimal",
          "id"             => build.id,
          "number"         => build.number,
          "state"          => build.state,
          "duration"       => nil,
          "event_type"     => "push",
          "previous_state" => "passed",
          "pull_request_number" => build.pull_request_number,
          "pull_request_title" => build.pull_request_title,
          "started_at"     => "2010-11-12T13:00:00Z",
          "private"        => false,
          "priority"       => false,
          "finished_at"    => nil }}]})
    }
  end

  describe "branches private repository, private API, authenticated as user with access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/repo/#{repo.id}/branches?limit=1", {}, headers)                           }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example    { expect(parsed_body).to eql_json({
      "@type"              => "branches",
      "@href"              => "/v3/repo/#{repo.id}/branches?limit=1",
      "@representation"    => "standard",
      "@pagination"        => {
        "limit"            => 1,
        "offset"           => 0,
        "count"            => 1,
        "is_first"         => true,
        "is_last"          => true,
        "next"             => nil,
        "prev"             => nil,
        "first"            => {
          "@href"          => "/v3/repo/#{repo.id}/branches?limit=1",
          "offset"         => 0,
          "limit"          => 1 },
        "last"             => {
          "@href"          => "/v3/repo/#{repo.id}/branches?limit=1",
          "offset"         => 0,
          "limit"          => 1 }},
      "branches"           => [{
        "@type"            => "branch",
        "@href"            => "/v3/repo/#{repo.id}/branch/master",
        "@representation"  => "standard",
        "name"             => "master",
        "default_branch"   => true,
        "exists_on_github" => true,
        "repository"       => {
          "@type"          => "repository",
          "@href"          => "/v3/repo/#{repo.id}",
          "@representation"=> "minimal",
          "id"             => repo.id,
          "name"           => "minimal",
          "slug"           => "svenfuchs/minimal"},
        "last_build"       => {
          "@type"          => "build",
          "@href"          => "/v3/build/#{build.id}",
          "@representation"=> "minimal",
          "id"             => build.id,
          "number"         => build.number,
          "state"          => build.state,
          "duration"       => nil,
          "event_type"     => "push",
          "previous_state" => "passed",
          "pull_request_number" => build.pull_request_number,
          "pull_request_title" => build.pull_request_title,
          "started_at"     => "2010-11-12T13:00:00Z",
          "private"        => false,
          "priority"       => false,
          "finished_at"    => nil }}]})
    }
  end

  describe "filtering by name" do
    describe "mast" do
      before     { get("/v3/repo/#{repo.id}/branches?branch.name=mast") }
      example    { expect(last_response).to be_ok }
      example    { expect(parsed_body["branches"]).not_to be_empty }
    end

    describe "some_fake_name" do
      before     { get("/v3/repo/#{repo.id}/branches?branch.name=some_fake_name") }
      example    { expect(last_response).to be_ok }
      example    { expect(parsed_body["branches"]).to be_empty }
    end
  end

  describe "filtering by exists_on_github" do
    describe "false" do
      before     { get("/v3/repo/#{repo.id}/branches?branch.exists_on_github=false") }
      example    { expect(last_response).to be_ok }
      example    { expect(parsed_body["branches"]).to be_empty }
    end

    describe "true" do
      before     { get("/v3/repo/#{repo.id}/branches?branch.exists_on_github=true") }
      example    { expect(last_response).to be_ok }
      example    { expect(parsed_body["branches"]).not_to be_empty }
    end
  end

  describe "sorting by name" do
    before  { get("/v3/repo/#{repo.id}/branches?sort_by=name&limit=1") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body["@pagination"]).to eql_json({
        "limit"            => 1,
        "offset"           => 0,
        "count"            => 1,
        "is_first"         => true,
        "is_last"          => true,
        "next"             => nil,
        "prev"             => nil,
        "first"            => {
          "@href"          => "/v3/repo/#{repo.id}/branches?sort_by=name&limit=1",
          "offset"         => 0,
          "limit"          => 1 },
        "last"             => {
          "@href"          => "/v3/repo/#{repo.id}/branches?sort_by=name&limit=1",
          "offset"         => 0,
          "limit"          => 1 }})
    }
  end

  describe "sorting by last_build" do
    let!(:repo) { FactoryBot.create(:repository_without_last_build) }
    let!(:build1) { FactoryBot.create(:v3_build, number: 10) }
    let!(:build2) { FactoryBot.create(:v3_build, number: 11) }
    let!(:branch1) { FactoryBot.create(:branch, name: 'older', last_build: build1, repository: repo) }
    let!(:branch2) { FactoryBot.create(:branch, name: 'newer', last_build: build2, repository: repo) }
    let!(:branch3) { FactoryBot.create(:branch, name: 'no-builds', last_build: nil, repository: repo) }

    context 'desc' do
      before  { get("/v3/repo/#{repo.id}/branches?sort_by=last_build:desc&limit=10") }
      example { expect(last_response).to be_ok }
      example {
        branch_names = parsed_body["branches"].map { |branch| branch['name'] }
        expect(branch_names).to be == ['newer', 'older']
      }
    end

    context 'asc' do
      before  { get("/v3/repo/#{repo.id}/branches?sort_by=last_build:asc&limit=10") }
      example { expect(last_response).to be_ok }
      example {
        branch_names = parsed_body["branches"].map { |branch| branch['name'] }
        expect(branch_names).to be == ['older', 'newer']
      }
    end
  end

  describe "sorting by name:desc" do
    before  { get("/v3/repo/#{repo.id}/branches?sort_by=name%3Adesc&limit=1") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body["@pagination"]).to eql_json({
        "limit"            => 1,
        "offset"           => 0,
        "count"            => 1,
        "is_first"         => true,
        "is_last"          => true,
        "next"             => nil,
        "prev"             => nil,
        "first"            => {
          "@href"          => "/v3/repo/#{repo.id}/branches?sort_by=name%3Adesc&limit=1",
          "offset"         => 0,
          "limit"          => 1 },
        "last"             => {
          "@href"          => "/v3/repo/#{repo.id}/branches?sort_by=name%3Adesc&limit=1",
          "offset"         => 0,
          "limit"          => 1 }})
    }
  end

  describe "sorting by exists_on_github" do
    before  { get("/v3/repo/#{repo.id}/branches?sort_by=exists_on_github&limit=1") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body["@pagination"]).to eql_json({
        "limit"            => 1,
        "offset"           => 0,
        "count"            => 1,
        "is_first"         => true,
        "is_last"          => true,
        "next"             => nil,
        "prev"             => nil,
        "first"            => {
          "@href"          => "/v3/repo/#{repo.id}/branches?sort_by=exists_on_github&limit=1",
          "offset"         => 0,
          "limit"          => 1 },
        "last"             => {
          "@href"          => "/v3/repo/#{repo.id}/branches?sort_by=exists_on_github&limit=1",
          "offset"         => 0,
          "limit"          => 1 }})
    }
  end

  describe "sorting by default_branch" do
    before  { get("/v3/repo/#{repo.id}/branches?sort_by=default_branch&limit=1") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body["@pagination"]).to eql_json({
        "limit"            => 1,
        "offset"           => 0,
        "count"            => 1,
        "is_first"         => true,
        "is_last"          => true,
        "next"             => nil,
        "prev"             => nil,
        "first"            => {
          "@href"          => "/v3/repo/#{repo.id}/branches?sort_by=default_branch&limit=1",
          "offset"         => 0,
          "limit"          => 1 },
        "last"             => {
          "@href"          => "/v3/repo/#{repo.id}/branches?sort_by=default_branch&limit=1",
          "offset"         => 0,
          "limit"          => 1 }})
    }
  end

  describe "sorting by unknown sort field" do
    before  { get("/v3/repo/#{repo.id}/branches?sort_by=name:desc,foo&limit=1") }
    example { expect(last_response).to be_ok }
    example { expect(parsed_body["@warnings"]).to eql_json([{
      "@type"       => "warning",
      "message"     => "query value foo for sort_by not a valid sort mode, ignored",
      "warning_type"=> "ignored_value",
      "parameter"   => "sort_by",
      "value"       => "foo"
    }])}
  end
end
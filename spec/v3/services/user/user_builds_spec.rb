# Yanking a ton of this from User and Builds specs, since we need both and this
#   app is 🍌 and I'm having a hard time figuring it out right now.
#
describe Travis::API::V3::Services::Builds::ForCurrentUser, set_app: true do
  include Support::Formats

  let(:user) { Travis::API::V3::Models::User.find_by_login('svenfuchs') }

  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                  }}

  let(:repo)   { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build)  { repo.builds.first }
  let(:stages) { build.stages }
  let(:jobs)   { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:parsed_body) { JSON.load(body) }

  let(:url) { "/v3/user/builds" }

  before do
    user.education = true
    user.save!

    build.update_attributes(sender_id: repo.owner.id, sender_type: 'User')

    test   = build.stages.create(number: 1, name: 'test')
    deploy = build.stages.create(number: 2, name: 'deploy')

    build.jobs[0, 2].each { |job| job.update_attributes!(stage: test) }
    build.jobs[2, 2].each { |job| job.update_attributes!(stage: deploy) }

    build.reload
  end

  describe "builds for user" do
    before do
      Timecop.freeze(Time.now)
      get(url, {}, headers)
    end

    after do
      Timecop.return
    end

    it "is ok" do
      expect(last_response).to be_ok
    end

    it "is recognizable as a list of builds" do
      expect(parsed_body).to eql_json({
        "@type"           => "builds",
        "@href"           => url,
        "@representation" => "standard",
        "@pagination"     => {
          "limit"    => 20,
          "offset"   => 0,
          "count"    => 1,
          "is_first" => true,
          "is_last"  => true,
          "next"     => nil,
          "prev"     => nil,
          "first" => {
            "@href"  => url,
            "offset" => 0,
            "limit"  => 20
          },
          "last" => {
            "@href"  => url,
            "offset" => 0,
            "limit"  => 20
          }
        },
        "builds" => [{
          "@type"           => "build",
          "@href"           => "/v3/build/#{build.id}",
          "@representation" => "standard",
          "@permissions" => {
            "read"    => true,
            "cancel"  => false,
            "restart" => false
          },
          "id"                  => build.id,
          "number"              => "3",
          "private"             => false,
          "state"               => "configured",
          "duration"            => nil,
          "event_type"          => "push",
          "previous_state"      => "passed",
          "pull_request_number" => nil,
          "pull_request_title"  => nil,
          "started_at"          => "2010-11-12T13:00:00Z",
          "finished_at"         => nil,
          "stages" => [{
             "@type"           => "stage",
             "@representation" => "minimal",
             "id"              => stages[0].id,
             "number"          => 1,
             "name"            => "test",
             "state"           => stages[0].state,
             "started_at"      => stages[0].started_at,
             "finished_at"     => stages[0].finished_at
            },
            {"@type"           => "stage",
             "@representation" => "minimal",
             "id"              => stages[1].id,
             "number"          => 2,
             "name"            => "deploy",
             "state"           => stages[1].state,
             "started_at"      => stages[1].started_at,
             "finished_at"     => stages[1].finished_at
             }
          ],
          "jobs" => [
            {
            "@type"           => "job",
            "@href"           => "/v3/job/#{jobs[0].id}",
            "@representation" => "minimal",
            "id"              => jobs[0].id},
            {
            "@type"           => "job",
            "@href"           => "/v3/job/#{jobs[1].id}",
            "@representation" => "minimal",
            "id"              => jobs[1].id},
            {
            "@type"           => "job",
            "@href"           => "/v3/job/#{jobs[2].id}",
            "@representation" => "minimal",
            "id"              => jobs[2].id},
            {
            "@type"           => "job",
            "@href"           => "/v3/job/#{jobs[3].id}",
            "@representation" => "minimal",
            "id"              => jobs[3].id}],
          "repository" => {
            "@type"           => "repository",
            "@href"           => "/v3/repo/#{repo.id}",
            "@representation" => "minimal",
            "id"              => repo.id,
            "name"            => "minimal",
            "slug"            => "svenfuchs/minimal"},
          "branch" => {
            "@type"           => "branch",
            "@href"           => "/v3/repo/#{repo.id}/branch/master",
            "@representation" => "minimal",
            "name"            => "master"},
          "tag"               =>  nil,
          "commit" => {
            "@type"           => "commit",
            "@representation" => "minimal",
            "id"              => 5,
            "sha"             => "add057e66c3e1d59ef1f",
            "ref"             => "refs/heads/master",
            "message"         => "unignore Gemfile.lock",
            "compare_url"     => "https://github.com/svenfuchs/minimal/compare/master...develop",
            "committed_at"    => "2010-11-12T12:55:00Z"},
          "created_by"        => {
            "@type"           => "user",
            "@href"           => "/v3/user/1",
            "@representation" => "minimal",
            "id"              => 1,
            "login"           => "svenfuchs"},
          "updated_at" => json_format_time_with_ms(build.updated_at),
        }]
      })
    end
  end

  # describe "authenticated as user with access" do
  #   before  { get("/v3/user/#{user.id}", {}, headers) }
  #   example { expect(last_response).to be_ok          }
  #   example { expect(JSON.load(body)).to be ==        {
  #     "@type"            => "user",
  #     "@href"            => "/v3/user/#{user.id}",
  #     "@representation"  => "standard",
  #     "@permissions"     => {"read"=>true, "sync"=>true},
  #     "id"               => user.id,
  #     "login"            => "svenfuchs",
  #     "name"             =>"Sven Fuchs",
  #     "github_id"        => user.github_id,
  #     "avatar_url"       => "https://0.gravatar.com/avatar/07fb84848e68b96b69022d333ca8a3e2",
  #     "is_syncing"       => user.is_syncing,
  #     "synced_at"        => user.synced_at,
  #     "education"        => true
  #   }}
  # end
end

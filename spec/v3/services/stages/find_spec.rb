describe Travis::API::V3::Services::Stages::Find, set_app: true do
  let(:repo)   { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:build)  { repo.builds.first }
  let(:stages) { build.stages }
  let(:jobs)   { Travis::API::V3::Models::Build.find(build.id).jobs }
  let(:commit) { build.commit }
  let(:parsed_body) { JSON.load(body) }

  before do
    # TODO should this go into the scenario? is it ok to keep it here?
    test   = build.stages.create(number: 1, name: 'test')
    deploy = build.stages.create(number: 2, name: 'deploy')
    jobs[0, 2].each { |job| job.update!(stage: test) }
    jobs[2, 2].each { |job| job.update!(stage: deploy) }
  end

  describe "stages on public repository" do
    before     { get("/v3/build/#{build.id}/stages") }
    example    { expect(last_response).to be_ok }
    example       { expect(parsed_body).to eql_json({
      "@type"=>"stages",
      "@href"=>"/v3/build/#{build.id}/stages",
      "@representation"=>"standard",
      "stages"=>[{
        "@type"=>"stage",
        "@representation"=>"standard",
        "id"=>stages[0].id,
        "number"=>1,
        "name"=>"test",
        "state"=>stages[0].state,
        "started_at"=>stages[0].started_at,
        "finished_at"=>stages[0].finished_at,
        "jobs"=>[{
          "@type"=>"job",
          "@href"=>"/v3/job/#{stages[0].jobs[0].id}",
          "@representation"=>"minimal",
          "id"=>stages[0].jobs[0].id},
          {
          "@type"=>"job",
          "@href"=>"/v3/job/#{stages[0].jobs[1].id}",
          "@representation"=>"minimal",
          "id"=>stages[0].jobs[1].id}]}, {
        "@type"=>"stage",
        "@representation"=>"standard",
        "id"=>stages[1].id,
        "number"=>2,
        "name"=>"deploy",
        "state"=>stages[1].state,
        "started_at"=>stages[1].started_at,
        "finished_at"=>stages[1].finished_at,
        "jobs"=>[{
          "@type"=>"job",
          "@href"=>"/v3/job/#{stages[1].jobs[0].id}",
          "@representation"=>"minimal",
          "id"=>stages[1].jobs[0].id}, {
          "@type"=>"job",
          "@href"=>"/v3/job/#{stages[1].jobs[1].id}",
          "@representation"=>"minimal",
          "id"=>stages[1].jobs[1].id}
        ]}
      ]})
    }
  end

  describe "stages private repository, private API, authenticated as user with pull access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/build/#{build.id}/stages", {}, headers)                           }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(parsed_body).to eql_json({
      "@type"=>"stages",
      "@href"=>"/v3/build/#{build.id}/stages",
      "@representation"=>"standard",
      "stages"=>[{
        "@type"=>"stage",
        "@representation"=>"standard",
        "id"=>stages[0].id,
        "number"=>1,
        "name"=>"test",
        "state"=>stages[0].state,
        "started_at"=>stages[0].started_at,
        "finished_at"=>stages[0].finished_at,
        "jobs"=>[{
          "@type"=>"job",
          "@href"=>"/v3/job/#{stages[0].jobs[0].id}",
          "@representation"=>"minimal",
          "id"=>stages[0].jobs[0].id},
          {
          "@type"=>"job",
          "@href"=>"/v3/job/#{stages[0].jobs[1].id}",
          "@representation"=>"minimal",
          "id"=>stages[0].jobs[1].id}]}, {
        "@type"=>"stage",
        "@representation"=>"standard",
        "id"=>stages[1].id,
        "number"=>2,
        "name"=>"deploy",
        "state"=>stages[1].state,
        "started_at"=>stages[1].started_at,
        "finished_at"=>stages[1].finished_at,
        "jobs"=>[{
          "@type"=>"job",
          "@href"=>"/v3/job/#{stages[1].jobs[0].id}",
          "@representation"=>"minimal",
          "id"=>stages[1].jobs[0].id}, {
          "@type"=>"job",
          "@href"=>"/v3/job/#{stages[1].jobs[1].id}",
          "@representation"=>"minimal",
          "id"=>stages[1].jobs[1].id}
        ]}
      ]})
    }
  end

describe "stages private repository, private API, authenticated as user with push access" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true, push: true) }
    before        { allow_any_instance_of(Travis::API::V3::Permissions::Job).to receive(:delete_log?).and_return(true) }
    before        { allow_any_instance_of(Travis::API::V3::Permissions::Job).to receive(:debug?).and_return(true) }
    before        { repo.update_attribute(:private, true)                             }
    before        { get("/v3/build/#{build.id}/stages", {}, headers)                           }
    after         { repo.update_attribute(:private, false)                            }
    example       { expect(last_response).to be_ok                                    }
    example       { expect(parsed_body).to eql_json({
      "@type"=>"stages",
      "@href"=>"/v3/build/#{build.id}/stages",
      "@representation"=>"standard",
      "stages"=>[{
        "@type"=>"stage",
        "@representation"=>"standard",
        "id"=>stages[0].id,
        "number"=>1,
        "name"=>"test",
        "state"=>stages[0].state,
        "started_at"=>stages[0].started_at,
        "finished_at"=>stages[0].finished_at,
        "jobs"=>[{
          "@type"=>"job",
          "@href"=>"/v3/job/#{stages[0].jobs[0].id}",
          "@representation"=>"minimal",
          "id"=>stages[0].jobs[0].id},
          {
          "@type"=>"job",
          "@href"=>"/v3/job/#{stages[0].jobs[1].id}",
          "@representation"=>"minimal",
          "id"=>stages[0].jobs[1].id}]}, {
        "@type"=>"stage",
        "@representation"=>"standard",
        "id"=>stages[1].id,
        "number"=>2,
        "name"=>"deploy",
        "state"=>stages[1].state,
        "started_at"=>stages[1].started_at,
        "finished_at"=>stages[1].finished_at,
        "jobs"=>[{
          "@type"=>"job",
          "@href"=>"/v3/job/#{stages[1].jobs[0].id}",
          "@representation"=>"minimal",
          "id"=>stages[1].jobs[0].id}, {
          "@type"=>"job",
          "@href"=>"/v3/job/#{stages[1].jobs[1].id}",
          "@representation"=>"minimal",
          "id"=>stages[1].jobs[1].id}
        ]}
      ]})
    }
  end
end

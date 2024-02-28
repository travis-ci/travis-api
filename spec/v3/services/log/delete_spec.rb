describe Travis::API::V3::Services::Log::Delete, set_app: true do
  let(:user)        { FactoryBot.create(:user) }
  let(:repo)        { FactoryBot.create(:repository, owner_name: user.login, name: 'minimal', owner: user)}
  let(:repo2)       { FactoryBot.create(:repository, owner_name: user.login, name: 'minimal2', owner: user)}
  let(:build)       { FactoryBot.create(:build, repository: repo) }
  let(:build2)      { FactoryBot.create(:build, repository: repo2) }
  let(:job)         { Travis::API::V3::Models::Job.create(build: build, repository: repo) }
  let(:job2)        { Travis::API::V3::Models::Job.create(build: build2) }
  let(:job3)        { Travis::API::V3::Models::Job.create(build: build2) }
  let(:s3job)       { Travis::API::V3::Models::Job.create(build: build) }
  let(:token)       { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers)     { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:parsed_body) { JSON.load(body) }
  let(:log)         { Travis::API::V3::Models::Log.create(job: job) }
  let(:log2)        { Travis::API::V3::Models::Log.create(job: job2) }
  let(:s3log)       { Travis::API::V3::Models::Log.create(job: s3job, content: 'minimal log 1') }
  let(:xml_content) {
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <ListBucketResult xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">
    <Name>bucket</Name>
    <Prefix/>
    <Marker/>
    <MaxKeys>1000</MaxKeys>
    <IsTruncated>false</IsTruncated>
      <Contents>
          <Key>jobs/#{s3job.id}/log.txt</Key>
          <LastModified>2009-10-12T17:50:30.000Z</LastModified>
          <ETag>&quot;hgb9dede5f27731c9771645a39863328&quot;</ETag>
          <Size>20308738</Size>
          <StorageClass>STANDARD</StorageClass>
          <Owner>
              <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
              <DisplayName>mtd@amazon.com</DisplayName>
          </Owner>
          <body>$ git clean -fdx\nRemoving Gemfile.lock\n$ git fetch
          </body>
      </Contents>
    </ListBucketResult>"
  }

  around(:each) do |example|
    options = Travis.config.log_options
    Travis.config.log_options.s3 = { access_key_id: 'key', secret_access_key: 'secret' }
    example.run
    Travis.config.log_options = options
  end

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  before do
    allow_any_instance_of(Travis::API::V3::AccessControl::LegacyToken).to receive(:visible?).and_return(true)
    allow_any_instance_of(Travis::API::V3::Permissions::Job).to receive(:delete_log?).and_return(true)
    stub_request(:get, "https://bucket.s3.amazonaws.com/?max-keys=1000").
      to_return(:status => 200, :body => xml_content, :headers => {})
    stub_request(:get, "https://s3.amazonaws.com/archive.travis-ci.org/?prefix=jobs/#{job.id}/log.txt").
      to_return(:status => 200, :body => xml_content, :headers => {})
  end

  describe "not authenticated" do
    before  { delete("/v3/job/#{job.id}/log")      }
    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    }}
  end

  describe "missing log, authenticated" do
    before { job3.update(finished_at: Time.now, state: "passed")}

    example do
      stub_request(
        :get,
        "#{Travis.config.logs_api.url}/logs/#{job3.id}?by=job_id&source=api"
      ).to_return(status: 404)
      delete("/v3/job/#{job3.id}/log", {}, headers)
      expect(last_response.status).to be == 404
      expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "not_found",
        "error_message" => "log not found"
      }
    end
  end

  describe "sucessfully delete log" do
    before { job.update(finished_at: Time.now, state: "passed")}
    let(:remote_log_response) {
      JSON.dump(job_id: job.id,
      log_parts: [
        {
          number: 42,
          content: 'whoa noww',
          final: false
        },
        {
          number: 17,
          content: "is a party\e0m",
          final: false
        }
      ])
    }
    before { Timecop.freeze(Time.now) }

    let(:authorization) { { 'permissions' => ['repository_settings_read', 'repository_log_view'] } }
    example do
      stub_request(:get, "#{Travis.config.logs_api.url}/logs/#{job.id}?by=job_id&source=api").
        with(headers: {
               'Authorization' => 'token notset'
             }).to_return(status: 200, body: remote_log_response, headers: {})

      stub_request(:put, "#{Travis.config.logs_api.url}/logs/#{job.id}?removed_by=#{user.id}&source=api").
        with(
          body: "Log removed by #{user.name} at #{Time.now.utc.to_s}",
          headers: {
            'Authorization' => 'token notset',
            'Content-Type' => 'application/octet-stream'
          }).
        to_return(status: 200, body: remote_log_response, headers: {})

      stub_request(:get, "#{Travis.config.logs_api.url}/log-parts/#{job.id}").
        with(headers: {
               'Authorization' => 'token notset'
             }).
        to_return(status: 200, body: remote_log_response, headers: {})

      delete("/v3/job/#{job.id}/log", {}, headers)

      expect(last_response.status).to be == 200
      expect(JSON.load(body)).to be == {
        "@type" => "log",
        "@href" => "/v3/job/#{job.id}/log",
        "@representation" => "standard",
        "@permissions" => {
          "read" => true,
          "delete_log" => false,
          "cancel" => false,
          "restart" => false,
          "debug" => false,
          "view_log" => true
        },
        "id" => nil,
        "content" => nil,
        "log_parts" => [
          {
            "content" => "whoa noww",
            "final" => false,
            "number" => 42
          },
          {
            "content" => "is a party\e0m",
            "final" => false,
            "number" => 17
          }
        ],
        "@raw_log_href" => "/v3/job/#{job.id}/log.txt"
      }
    end
  end
end

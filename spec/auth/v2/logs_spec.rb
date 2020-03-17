describe 'v2 logs', auth_helpers: true, api_version: :v2, set_app: true do
  let(:user)  { FactoryBot.create(:user) }
  let(:repo)  { Repository.by_slug('svenfuchs/minimal').first }
  let(:build) { repo.builds.first }
  let(:job)   { build.matrix.first }
  let(:log)   { double(id: 1) }

  let(:xml_content) {
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <ListBucketResult xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">
    <Name>bucket</Name>
    <Prefix/>
    <Marker/>
    <MaxKeys>1000</MaxKeys>
    <IsTruncated>false</IsTruncated>
      <Contents>
          <Key>jobs/#{job.id}/log.txt</Key>
          <LastModified>2009-10-12T17:50:30.000Z</LastModified>
          <ETag>&quot;hgb9dede5f27731c9771645a39863328&quot;</ETag>
          <Size>20308738</Size>
          <StorageClass>STANDARD</StorageClass>
          <Owner>
              <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
              <DisplayName>mtd@amazon.com</DisplayName>
          </Owner>
          <body>#{archived_content}
          </body>
      </Contents>
    </ListBucketResult>"
  }

  let :log_from_api do
    {
      aggregated_at: Time.now,
      archive_verified: true,
      archived_at: Time.now,
      archiving: false,
      content: 'hello world. this is a really cool log',
      created_at: Time.now,
      id: 1,
      job_id: job.id,
      purged_at: nil,
      removed_at: nil,
      removed_by_id: nil,
      updated_at: Time.now
    }
  end

  let(:archived_content) { "$ git clean -fdx\nRemoving Gemfile.lock\n$ git fetch" }

  let(:log_url) { "#{Travis.config[:logs_api][:url]}/logs/1?by=id&source=api" }

  before do
    stub_request(:get, log_url).to_return(status: 200, body: %({"job_id": #{job.id}, "content": "content"}))
    stub_request(:get, "https://s3.amazonaws.com/archive.travis-ci.com/?prefix=jobs/#{job.id}/log.txt").
      to_return(status: 200, body: xml_content, headers: {})

    Fog.mock!
    storage = Fog::Storage.new({
      aws_access_key_id: 'key',
      aws_secret_access_key: 'secret',
      provider: 'AWS'
    })
    bucket = storage.directories.create(key: 'archive.travis-ci.org')
    file = bucket.files.create(
      key: "jobs/#{job.id}/log.txt",
      body: archived_content
    )
    remote = double('remote')
    allow(Travis::RemoteLog::Remote).to receive(:new).and_return(remote)
    allow(remote).to receive(:find_by_job_id).and_return(Travis::RemoteLog.new(log_from_api))
    allow(remote).to receive(:find_by_id).and_return(Travis::RemoteLog.new(log_from_api))
    allow(remote).to receive(:fetch_archived_url).and_return('https://s3.amazonaws.com/STUFFS')
  end

  after do
    Fog.unmock!
    Fog::Mock.reset
  end

  describe 'in public mode, with a private repo', mode: :public, repo: :private do
    describe 'GET /logs/%{log.id}' do
      it(:with_permission)    { should auth status: [200, 307], type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in public mode, with a public repo', mode: :public, repo: :public do
    describe 'GET /logs/%{log.id}' do
      it(:with_permission)    { should auth status: [200, 307], type: :json, empty: false }
      it(:without_permission) { should auth status: [200, 307], type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in private mode, with a public repo', mode: :private, repo: :public do
    describe 'GET /logs/%{log.id}' do
      it(:with_permission)    { should auth status: [200, 307], type: [:json, :text], empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  # +----------------------------------------------------+
  # |                                                    |
  # |   !!! THE ORIGINAL BEHAVIOUR ... DON'T TOUCH !!!   |
  # |                                                    |
  # +----------------------------------------------------+

  describe 'in private mode, with a private repo', mode: :private, repo: :private do
    describe 'GET /logs/%{log.id}' do
      it(:with_permission)    { should auth status: [200, 307], type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in org mode, with a public repo', mode: :org, repo: :public do
    describe 'GET /logs/%{log.id}' do
      it(:with_permission)    { should auth status: [200, 307], type: :json, empty: false }
      it(:without_permission) { should auth status: [200, 307], type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: [200, 307], type: :json, empty: false }
    end
  end
end

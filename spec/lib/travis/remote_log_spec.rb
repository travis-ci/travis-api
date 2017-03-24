require 'travis/remote_log'

describe Travis::RemoteLog do
  subject { described_class.new(attrs) }
  let(:attrs) { { id: 4, content: 'huh', job_id: 5 } }

  before :each do
    described_class.instance_variable_set(:@client, nil)
    described_class.instance_variable_set(:@archive_client, nil)
  end

  it 'has a default client' do
    expect(described_class.send(:client)).to_not be_nil
  end

  it 'has a default archive_client' do
    expect(described_class.send(:archive_client)).to_not be_nil
  end

  it 'delegates public methods to client' do
    client = mock('client')
    client.expects(:find_by_job_id)
    client.expects(:find_by_id)
    client.expects(:write_content_for_job_id)
    described_class.instance_variable_set(:@client, client)

    described_class.find_by_id
    described_class.find_by_job_id
    described_class.write_content_for_job_id
  end

  it 'delegates public methods to archive_client' do
    archive_client = mock('archive_client')
    archive_client.expects(:fetch_archived_url)
    described_class.instance_variable_set(:@archive_client, archive_client)

    described_class.fetch_archived_url
  end

  it 'has all the necessary attributes' do
    %i(
      aggregated_at
      archive_verified
      archived_at
      archiving
      content
      created_at
      id
      job_id
      purged_at
      removed_at
      removed_by_id
      updated_at
    ).each do |attr|
      expect { subject.public_send(attr) }.to_not raise_error
    end
  end

  it 'has a nil removed_by without a removed_by_id' do
    subject.removed_by_id = nil
    subject.removed_by.should be_nil
  end

  it 'has a non-nil removed_by with a removed_by_id' do
    user = mock('user')
    subject.removed_by_id = 4
    User.expects(:find).with(4).returns(user)
    subject.removed_by.should == user
  end

  it 'has a job' do
    job = mock('job')
    Job.expects(:find).with(attrs[:job_id]).returns(job)
    subject.job.should == job
  end

  it 'has archived content' do
    described_class.expects(:fetch_archived_url)
      .with(5, expires: nil)
      .returns('yep')
    subject.archived_url.should eq 'yep'
  end

  it 'has parts' do
    found_parts = [
      Travis::RemoteLogPart.new(number: 42, content: 'yey', final: false)
    ]
    described_class.stubs(:find_parts_by_job_id)
      .with(5, after: nil, part_numbers: [])
      .returns(found_parts)
    subject.parts.should eq found_parts
  end

  {
    nil => false,
    Time.now => true,
    'huh' => true
  }.each do |aggregated_at, is_aggregated|
    context "when aggregated_at=#{aggregated_at}" do
      before { subject.aggregated_at = aggregated_at }

      it "has aggregated?=#{is_aggregated}" do
        subject.aggregated?.should == is_aggregated
      end
    end
  end

  {
    [nil, nil] => false,
    [nil, true] => false,
    [nil, false] => false,
    [Time.now, false] => false,
    [Time.now, nil] => false,
    [Time.now, true] => true,
  }.each do |(archived_at, archive_verified), is_archived|
    context "when archived_at=#{archived_at.inspect} and " \
           "archive_verified=#{archive_verified.inspect}" do
      before do
        subject.archived_at = archived_at
        subject.archive_verified = archive_verified
      end

      it "has archived?=#{is_archived}" do
        subject.archived?.should == is_archived
      end
    end
  end

  it 'can serialize via #to_json' do
    from_json = JSON.parse(subject.to_json).fetch('log')
    from_json.fetch('id').should == attrs[:id]
    from_json.fetch('job_id').should == attrs[:job_id]
    from_json.fetch('type').should == 'Log'
    from_json.fetch('body').should == attrs[:content]
  end

  it 'can fake chunked serialization via #to_json' do
    from_json = JSON.parse(subject.to_json(chunked: true)).fetch('log')
    from_json.fetch('id').should == attrs[:id]
    from_json.fetch('job_id').should == attrs[:job_id]
    from_json.fetch('type').should == 'Log'
    from_json.fetch('parts').first.fetch('content').should == attrs[:content]
  end

  it 'can serialize removed logs via #to_json' do
    user_id = 8
    user = mock('user')
    user.stubs(:name).returns('Twizzler HotDog')
    user.stubs(:id).returns(user_id)

    now = mock('now')
    now.stubs(:utc).returns(now)
    now.stubs(:to_s).returns('whenebber')
    Time.stubs(:now).returns(now)

    subject.stubs(:removed_by).returns(user)
    subject.removed_at = now
    subject.removed_by_id = user_id

    from_json = JSON.parse(subject.to_json).fetch('log')
    from_json.fetch('id').should == attrs[:id]
    from_json.fetch('job_id').should == attrs[:job_id]
    from_json.fetch('type').should == 'Log'
    from_json.fetch('body').should == attrs[:content]
    from_json.fetch('removed_by').should == 'Twizzler HotDog'
    from_json.fetch('removed_at').should == 'whenebber'
  end

  it 'can be cleared' do
    content = 'Log removed by Floof MaGoof at sometime'
    user_id = 8

    client = mock('client')
    client.expects(:write_content_for_job_id)
      .with(attrs.fetch(:job_id), content: content, removed_by: user_id)
      .returns(described_class.new(content: content, removed_by: user_id))
    described_class.instance_variable_set(:@client, client)

    user = mock('user')
    user.expects(:name).returns('Floof MaGoof')
    user.expects(:id).returns(user_id)
    now = mock('now')
    now.expects(:utc).returns('sometime')
    Time.stubs(:now).returns(now)

    subject.clear!(user).should eq(content)
  end
end

describe Travis::RemoteLog::Client do
  let(:url) { 'http://loggo.example.com' }
  let(:token) { 'fafafafcoolbeansgeocitiesangelfire' }
  let :stubs do
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get('/logs/4') { [200, {}, JSON.dump(content: 'huh wow')] }
      stub.get('/logs/4/id') { [200, {}, JSON.dump(id: 4000)] }
      stub.put('/logs/8?removed_by=3') do
        [
          200,
          {},
          JSON.dump(
            content: 'why not eh',
            job_id: 8,
            removed_by_id: 3
          )
        ]
      end
    end
  end

  subject { described_class.new(url: url, token: token) }

  before do
    subject.instance_variable_set(
      :@conn,
      Faraday.new { |c| c.adapter :test, stubs }
    )
  end

  it 'can find logs by id' do
    subject.find_by_id(4).should_not be_nil
  end

  it 'can find logs by job id' do
    subject.find_by_job_id(4).should_not be_nil
  end

  it 'can find log ids by job id' do
    subject.find_id_by_job_id(4).should_not be_nil
  end

  it 'can write content for job id' do
    subject.write_content_for_job_id(8, content: 'oh hi', removed_by: 3)
      .should_not be_nil
  end

  context 'when the responses are sad' do
    let :stubs do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get('/logs/4') { [404, {}, ''] }
        stub.get('/logs/4/id') { [404, {}, ''] }
        stub.put('/logs/8') { [404, {}, ''] }
      end
    end

    it 'cannot find logs by id' do
      subject.find_by_id(4).should be_nil
    end

    it 'cannot find logs by job id' do
      subject.find_by_job_id(4).should be_nil
    end

    it 'cannot find log ids by job id' do
      subject.find_id_by_job_id(4).should be_nil
    end

    it 'cannot write content for job id' do
      expect { subject.write_content_for_job_id(8, content: 'nah') }
        .to raise_error(Travis::RemoteLog::Client::Error)
    end
  end
end

describe Travis::RemoteLog::ArchiveClient do
  subject do
    described_class.new(
      access_key_id: 'AKFLAH',
      secret_access_key: 'SECRETSECRETWOWNEAT',
      bucket_name: 'fluffernutter-pretzel-pie'
    )
  end

  let(:s3) { mock('s3') }

  before do
    subject.instance_variable_set(:@s3, s3)
    s3.stubs(:directories).returns(s3)
    s3.stubs(:get)
      .with('fluffernutter-pretzel-pie', prefix: 'jobs/9/log.txt')
      .returns(s3)
    s3.stubs(:files).returns([s3])
  end

  it 'fetches public archived URLs' do
    s3.stubs(:public?).returns(true)
    s3.stubs(:public_url).returns('https://wowneat.example.com/flah')
    subject.fetch_archived_url(9).should eq 'https://wowneat.example.com/flah'
  end

  it 'fetches private archived URLs' do
    s3.stubs(:public?).returns(false)
    s3.stubs(:url).with(8001)
      .returns('https://whoabud.example.com/flah?sig=ya&exp=nah')
    subject.fetch_archived_url(9, expires: 8001)
      .should eq'https://whoabud.example.com/flah?sig=ya&exp=nah'
  end
end

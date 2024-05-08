require 'travis/remote_log'

describe Travis::RemoteLog do
  subject { described_class.new(attrs) }
  let(:job_id) { 5 }
  let(:attrs) { { id: 4, content: archived_content, job_id: job_id } }
  let(:archived_content) { 'hello world' }

  before :each do
    described_class::Remote.instance_variable_set(:@clients, nil)
    described_class::Remote.instance_variable_set(:@archive_clients, nil)

    class FakeFile
      attr_accessor :body
      attr_accessor :key
      def initialize(data)
        @body = data
        @key = 'key'
      end
    end

    file = FakeFile.new(archived_content)

    allow_any_instance_of(::Travis::RemoteLog::ArchiveClient).to receive(:fetch_archived).and_return(file)
    allow_any_instance_of(::Travis::RemoteLog::ArchiveClient).to receive(:fetch_archived_log_content).and_return(file.body)
  end

  it 'has a default client' do
    expect(described_class::Remote.new.send(:client)).to_not be_nil
  end

  it 'has a default archive_client' do
    expect(described_class::Remote.new.send(:archive_client)).to_not be_nil
  end

  it 'delegates public methods to client' do
    client = double('client')
    expect(client).to receive(:find_by_job_id)
    expect(client).to receive(:find_by_id)
    expect(client).to receive(:write_content_for_job_id)
    remote = described_class::Remote.new
    expect(remote).to receive(:client).and_return(client).exactly(3).times

    remote.find_by_id
    remote.find_by_job_id
    remote.write_content_for_job_id
  end

  it 'delegates public methods to archive_client' do
    archive_client = double('archive_client')
    expect(archive_client).to receive(:fetch_archived_url)
    remote = described_class::Remote.new
    expect(remote).to receive(:archive_client).and_return(archive_client)

    remote.fetch_archived_url
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
    expect(subject.removed_by).to be_nil
  end

  it 'has a non-nil removed_by with a removed_by_id' do
    user = double('user')
    subject.removed_by_id = 4
    expect(User).to receive(:find).with(4).and_return(user)
    expect(subject.removed_by).to eq(user)
  end

  it 'has a job' do
    job = double('job')
    expect(Job).to receive(:find).with(attrs[:job_id]).and_return(job)
    expect(subject.job).to eq(job)
  end

  it 'has archived content' do
    remote = double()
    expect(remote).to receive(:fetch_archived_url)
      .with(5, expires: nil)
      .and_return('yep')
    expect(described_class::Remote).to receive(:new).and_return(remote)
    expect(subject.archived_url).to eq 'yep'
  end

  it 'has parts' do
    found_parts = [
      Travis::RemoteLogPart.new(number: 42, content: 'yey', final: false)
    ]
    remote = double()
    expect(described_class::Remote).to receive(:new).and_return(remote)
    allow(remote).to receive(:find_parts_by_job_id)
      .with(5, after: nil, part_numbers: [])
      .and_return(found_parts)
    expect(subject.parts).to eq found_parts
  end

  {
    nil => false,
    Time.now => true,
    'huh' => true
  }.each do |aggregated_at, is_aggregated|
    context "when aggregated_at=#{aggregated_at}" do
      before { subject.aggregated_at = aggregated_at }

      it "has aggregated?=#{is_aggregated}" do
        expect(subject.aggregated?).to eq(is_aggregated)
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
        expect(subject.archived?).to eq(is_archived)
      end
    end
  end

  it 'can serialize via #to_json' do
    from_json = JSON.parse(subject.to_json).fetch('log')
    expect(from_json.fetch('id')).to eq(attrs[:id])
    expect(from_json.fetch('job_id')).to eq(attrs[:job_id])
    expect(from_json.fetch('type')).to eq('Log')
    expect(from_json.fetch('body')).to eq(attrs[:content])
  end

  it 'can serialize chunked via #to_json' do
    allow(subject).to receive(:parts).and_return([
      Travis::RemoteLogPart.new(
        number: 8, content: 'whats that', final: false
      ),
      Travis::RemoteLogPart.new(
        number: 11, content: 'whats thaaaaat', final: false
      )
    ])

    from_json = JSON.parse(
      subject.to_json(
        chunked: true,
        after: 2,
        part_numbers: [8, 11]
      )
    ).fetch('log')

    expect(from_json.fetch('id')).to eq(attrs[:id])
    expect(from_json.fetch('job_id')).to eq(attrs[:job_id])
    expect(from_json.fetch('type')).to eq('Log')
    expect(from_json.fetch('parts')).to eq([
      { 'number' => 8, 'content' => 'whats that', 'final' => false },
      { 'number' => 11, 'content' => 'whats thaaaaat', 'final' => false },
    ])
    expect(from_json).not_to include('body')
  end

  it 'can serialize removed logs via #to_json' do
    user_id = 8
    user = double('user')
    allow(user).to receive(:name).and_return('Twizzler HotDog')
    allow(user).to receive(:id).and_return(user_id)

    now = double('now')
    allow(now).to receive(:utc).and_return(now)
    allow(now).to receive(:to_s).and_return('whenebber')
    allow(Time).to receive(:now).and_return(now)

    allow(subject).to receive(:removed_by).and_return(user)
    subject.removed_at = now
    subject.removed_by_id = user_id

    from_json = JSON.parse(subject.to_json).fetch('log')
    expect(from_json.fetch('id')).to eq(attrs[:id])
    expect(from_json.fetch('job_id')).to eq(attrs[:job_id])
    expect(from_json.fetch('type')).to eq('Log')
    expect(from_json.fetch('body')).to eq(attrs[:content])
    expect(from_json.fetch('removed_by')).to eq('Twizzler HotDog')
    expect(from_json.fetch('removed_at')).to eq('whenebber')
  end

  it 'can be cleared' do
    content = 'Log removed by Floof MaGoof at sometime'
    user_id = 8

    remote = double('remote')
    expect(described_class::Remote).to receive(:new).and_return(remote)
    expect(remote).to receive(:write_content_for_job_id)
      .with(attrs.fetch(:job_id), content: content, removed_by: user_id)
      .and_return(described_class.new(content: content, removed_by: user_id))

    user = double('user')
    expect(user).to receive(:name).and_return('Floof MaGoof')
    expect(user).to receive(:id).and_return(user_id)
    now = double('now')
    expect(now).to receive(:utc).and_return('sometime')
    allow(Time).to receive(:now).and_return(now)

    expect(subject.clear!(user)).to eq(content)
  end

  context 'when the log is not archived' do
    let(:local_content) { 'Content from DB' }

    before do
      subject.archived_at = nil
      subject.archive_verified = false
      subject.content = local_content
    end

    it 'does not fetch archived content' do
      expect(subject).not_to receive(:archived_log_content)
      from_json = JSON.parse(subject.to_json).fetch('log')
      expect(from_json.fetch('body')).to eq(local_content)
    end
  end

  context 'when the log is archived' do
    before do
      subject.archived_at = Time.now
      subject.archive_verified = true
    end

    it 'fetches archived content' do
      expect(subject).to receive(:archived_log_content).and_return(archived_content)
      from_json = JSON.parse(subject.to_json).fetch('log')
      expect(from_json.fetch('body')).to eq(archived_content)
    end
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

      stub.get('/log-parts/8?after=4&part_numbers=42,17') do
        [
          200,
          {},
          JSON.dump(
            job_id: 8,
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
            ]
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
    expect(subject.find_by_id(4)).not_to be_nil
  end

  it 'can find logs by job id' do
    expect(subject.find_by_job_id(4)).not_to be_nil
  end

  it 'can find log ids by job id' do
    expect(subject.find_id_by_job_id(4)).not_to be_nil
  end

  it 'can write content for job id' do
    expect(subject.write_content_for_job_id(8, content: 'oh hi', removed_by: 3))
      .not_to be_nil
  end

  it 'can find parts by job id' do
    expect(subject.find_parts_by_job_id(8, after: 4, part_numbers: [42, 17]))
      .not_to be_nil
  end

  context 'when the responses are sad' do
    let :stubs do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get('/logs/4') { [404, {}, ''] }
        stub.get('/logs/4/id') { [404, {}, ''] }
        stub.put('/logs/8') { [404, {}, ''] }
        stub.get('/log-parts/8?after=4&part_numbers=42,17') { [404, {}, ''] }
      end
    end

    it 'cannot find logs by id' do
      expect(subject.find_by_id(4)).to be_nil
    end

    it 'cannot find logs by job id' do
      expect(subject.find_by_job_id(4)).to be_nil
    end

    it 'cannot find log ids by job id' do
      expect(subject.find_id_by_job_id(4)).to be_nil
    end

    it 'cannot write content for job id' do
      expect { subject.write_content_for_job_id(8, content: 'nah') }
        .to raise_error(Travis::RemoteLog::Client::Error)
    end

    it 'cannot find parts by job id' do
      expect do
        subject.find_parts_by_job_id(8, after: 4, part_numbers: [42, 17])
      end.to raise_error(Travis::RemoteLog::Client::Error)
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

  let(:s3) { double('s3') }
  let(:archived_content) { 'hello world' }
  let(:archived_content_url) { 'https://wowneat.example.com/flah' }
  let(:archived_content_public) { true }

  before do
    subject.instance_variable_set(:@s3, s3)
    allow(s3).to receive(:directories).and_return(s3)
    allow(s3).to receive(:list_objects_v2).and_return([s3])
    allow(s3).to receive(:get)
      .with('fluffernutter-pretzel-pie', prefix: 'jobs/9/log.txt')
      .and_return(s3)
    allow(s3).to receive(:files).and_return([s3])

    class FakeFile
      attr_accessor :body
      attr_accessor :key

      def public_url
        @archived_content_url
      end

      def url(expires=nil)
        @archived_content_url
      end

      def public?
        @public
      end

      def initialize(data, url, pub)
        @body = data
        @archived_content_url = url
        @public = pub
      end
    end

    file = FakeFile.new(archived_content, archived_content_url, archived_content_public)

    allow_any_instance_of(::Travis::RemoteLog::ArchiveClient).to receive(:fetch_archived).and_return(file)

  end

  context 'for public url' do
    let(:archived_content_url) { 'https://wowneat.example.com/flah' }
    let(:archived_content_public) { true }
    it 'fetches archived URLs' do
      expect(subject.fetch_archived_url(9)).to eq 'https://wowneat.example.com/flah'
    end
  end

  context 'for private url' do
    let(:archived_content_url) { 'https://whoabud.example.com/flah?sig=ya&exp=nah' }
    let(:archived_content_public) { false }
    it 'fetches private archived URLs' do
      expect(subject.fetch_archived_url(9, expires: 8001))
        .to eq'https://whoabud.example.com/flah?sig=ya&exp=nah'
    end
  end
end

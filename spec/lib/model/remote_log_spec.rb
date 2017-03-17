require 'travis/model/remote_log'

describe RemoteLog do
  subject { described_class.new(attrs) }
  let(:attrs) { { id: 4, content: 'huh', job_id: 5 } }

  before :each do
    described_class.instance_variable_set(:@client, nil)
  end

  it 'has a default client' do
    expect(described_class.send(:client)).to_not be_nil
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

  it 'never has parts' do
    subject.parts.should be_empty
    subject.log_parts.should be_empty
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
    from_json.fetch('content').should == attrs[:content]
    from_json.fetch('created_at').should be_nil
    from_json.fetch('job_id').should == attrs[:job_id]
    from_json.fetch('updated_at').should be_nil
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

describe RemoteLog::Client do
  let(:url) { 'http://loggo.example.com' }
  let(:token) { 'fafafafcoolbeansgeocitiesangelfire' }
  let :stubs do
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get('/logs/4') { [200, {}, JSON.dump(content: 'huh wow')] }
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

  it 'can write content for job id' do
    subject.write_content_for_job_id(8, content: 'oh hi', removed_by: 3)
      .should_not be_nil
  end

  context 'when the responses are sad' do
    let :stubs do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get('/logs/4') { [404, {}, ''] }
        stub.put('/logs/8') { [404, {}, ''] }
      end
    end

    it 'cannot find logs by id' do
      subject.find_by_id(4).should be_nil
    end

    it 'cannot find logs by job id' do
      subject.find_by_job_id(4).should be_nil
    end

    it 'cannot write content for job id' do
      expect { subject.write_content_for_job_id(8, content: 'nah') }
        .to raise_error(RemoteLog::Client::Error)
    end
  end
end

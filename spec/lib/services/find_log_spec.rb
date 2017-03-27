describe Travis::Services::FindLog do
  let!(:job) { Factory(:test) }
  let(:log) { nil }
  let(:service) { described_class.new(stub('user'), params) }

  attr_reader :params

  describe 'run', logs_api_enabled: false do
    let(:log)     { job.log }

    it 'finds the log with the given id' do
      @params = { id: log.id }
      service.run.should == log
    end

    it 'finds the log with the given job_id' do
      @params = { job_id: job.id }
      service.run.should == log
    end

    it 'does not raise if the log could not be found' do
      @params = { id: log.id + 1 }
      lambda { service.run }.should_not raise_error
    end
  end
end

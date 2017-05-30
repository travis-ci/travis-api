describe Travis::Services::FindLog do
  let(:params) { {} }
  let(:service) { described_class.new(stub('user'), params) }

  describe 'run' do
    it 'finds the log with the given id' do
      params[:id] = 1
      found_by_id = mock('found-by-id')
      Travis::RemoteLog.expects(:find_by_id).with(1).returns(found_by_id)
      service.run.should == found_by_id
    end

    it 'finds the log with the given job_id' do
      params[:job_id] = 2
      found_by_job_id = mock('found-by-job-id')
      Travis::RemoteLog.expects(:find_by_job_id).with(2).returns(found_by_job_id)
      service.run.should == found_by_job_id
    end

    it 'does not raise if the log could not be found' do
      params[:id] = 17
      Travis::RemoteLog.expects(:find_by_id).with(17).returns(nil)
      lambda { service.run }.should_not raise_error
    end
  end
end

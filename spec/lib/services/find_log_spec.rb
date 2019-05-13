describe Travis::Services::FindLog do
  let(:params) { {} }
  let(:service) { described_class.new(stub('user'), params) }
  let(:job) { FactoryGirl.create(:job) }

  describe 'run' do
    it 'finds the log with the given id' do
      params[:id] = 1
      found_by_id = stub('found-by-id', job_id: job.id)
      Travis::RemoteLog.expects(:find_by_id).with(1).returns(found_by_id)
      service.run.should == found_by_id
    end

    it 'finds the log with the given job_id' do
      params[:job_id] = job.id
      found_by_job_id = stub('found-by-job-id', job_id: job.id)
      Travis::RemoteLog.expects(:find_by_job_id).with(job.id, {:platform => 'com'}).returns(found_by_job_id)
      service.run.should == found_by_job_id
    end

    it 'does not raise if the log could not be found' do
      params[:id] = 17
      Travis::RemoteLog.expects(:find_by_id).with(17).returns(nil)
      lambda { service.run }.should_not raise_error
    end
  end
end

describe Travis::Services::FindLog do
  let(:params) { {} }
  let(:service) { described_class.new(double('user'), params) }
  let(:job) { FactoryBot.create(:job) }

  describe 'run' do
    it 'finds the log with the given id' do
      params[:id] = 1
      found_by_id = double('found-by-id', job_id: job.id)
      remote = double('remote')
      remote.expects(:find_by_id).with(1).returns(found_by_id)
      Travis::RemoteLog::Remote.expects(:new).returns(remote)
      expect(service.run).to eq(found_by_id)
    end

    it 'finds the log with the given job_id' do
      params[:job_id] = job.id
      found_by_job_id = double('found-by-job-id', job_id: job.id)
      remote = double('remote')
      remote.expects(:find_by_job_id).with(job.id).returns(found_by_job_id)
      Travis::RemoteLog::Remote.expects(:new).returns(remote)
      expect(service.run).to eq(found_by_job_id)
    end

    it 'does not raise if the log could not be found' do
      params[:id] = 17
      remote = double('remote')
      remote.expects(:find_by_id).with(17).returns(nil)
      Travis::RemoteLog::Remote.expects(:new).returns(remote)
      expect { service.run }.not_to raise_error
    end
  end
end

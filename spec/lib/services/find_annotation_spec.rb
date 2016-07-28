describe Travis::Services::FindAnnotations do
  let(:job) { Factory(:test) }
  let!(:annotation) { Factory(:annotation, job: job) }
  let(:service) { described_class.new(params) }

  attr_reader :params

  describe 'run' do
    it 'finds annotations by a given list of ids' do
      @params = { ids: [annotation.id] }
      service.run.should eq([annotation])
    end

    it 'finds annotations by job_id' do
      @params = { job_id: job.id }
      service.run.should eq([annotation])
    end
  end
end

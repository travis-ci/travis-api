describe Travis::API::V3::Models::Job do
  let(:job) { Factory(:job, state: nil) }
  subject { Travis::API::V3::Models::Job.find_by_id(job.id).state }

  it { should eq 'created' }
end

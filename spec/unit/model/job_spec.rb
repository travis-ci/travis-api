describe Job do
  context 'given state is nil' do
    let(:job) { FactoryGirl.build(:job, state: nil) }
    subject { job.state }

    it { should eq :created }
  end
end

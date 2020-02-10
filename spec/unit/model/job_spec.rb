describe Job do
  context 'given state is nil' do
    let(:job) { FactoryBot.build(:job, state: nil) }
    expect(job.state).to eq(:created)
  end
end

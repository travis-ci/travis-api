describe Job do
  let(:job) { FactoryBot.build(:job, state: nil) }

  it 'defaults state to :created' do
    expect(job.state).to eq(:created)
  end
end

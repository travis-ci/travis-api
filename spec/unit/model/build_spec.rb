describe Build do
  let(:build) { FactoryBot.build(:build, state: nil) }

  it 'defaults state to :created' do
    expect(build.state).to eq(:created)
  end
end

describe Build do
  context 'given state is nil' do
    let(:build) { FactoryBot.build(:build, state: nil) }
    expect(build.state).to eq(:created)
  end
end

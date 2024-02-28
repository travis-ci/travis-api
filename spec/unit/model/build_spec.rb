describe Build do
  let(:build) { FactoryBot.build(:build, state: :created) }

  it 'defaults state to :created' do
    expect(build.state.to_sym).to eq(:created)
  end
end

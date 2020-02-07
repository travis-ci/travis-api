describe Build do
  context 'given state is nil' do
    let(:build) { FactoryBot.build(:build, state: nil) }
    subject { build.state }

    it { should eq :created }
  end
end

describe Travis::API::V3::Models::CreditsResult do
  let(:user) { FactoryBot.create(:user) }
  let(:attributes) do
    {
      'users' => 5,
      'minutes' => 1200,
      'os' => 'linux',
      'instance_size' => '2x-large'
    }
  end

  subject { Travis::API::V3::Models::CreditsCalculatorConfig.new(attributes) }

  context 'basic fields' do
    it 'returns basic fields' do
      attributes.each do |key, value|
        expect(subject.send(key)).to eq(value)
      end
    end
  end
end

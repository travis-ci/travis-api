describe Travis::API::V3::Models::SpotlightSummary do
  let(:user) { FactoryBot.create(:user) }
  let(:attributes) do
    {
      'id' => 1,
      'user_id' => 123,
      'repo_id' => 1223,
      'build_status' => 'complete',
      'repo_name' => 'myrepo',
      'builds' => 4,
      'duration' => 47,
      'credits' => 23,
      'license_credits' => 20,
      'time' => '2022-02-08'
    }
  end

  subject { Travis::API::V3::Models::SpotlightSummary.new(attributes) }

  context 'basic fields' do
    it 'returns basic fields' do
      attributes.each do |key, value|
        expect(subject.send(key)).to eq(value)
      end
    end
  end
end

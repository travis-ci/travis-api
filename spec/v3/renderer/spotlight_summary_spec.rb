describe Travis::API::V3::Renderer::SpotlightSummary do
  let(:object) { 
    {
      'data' => [
        {
          'id': 1,
          'user_id': 123,
          'repo_id': 1223,
          'build_status': 'complete',
          'repo_name': 'myrepo',
          'builds': 4,
          'duration': 47,
          'credits': 23,
          'license_credits': 20,
          'time': '2022-02-08'
        }
      ]
    } 
  }
  
  subject { Travis::API::V3::Renderer::SpotlightSummary }

  describe "basic check" do
    it "returns a basic representation of the object" do
      expect(subject.render(object)).to eq(
        {
          '@type': 'spotlight_summary',
          data: object['data']
        }
      )
    end
  end

  describe '#available_attributes' do
    it 'returns available attributes' do
      expect(subject.available_attributes).to eq([:data])
    end
  end
end

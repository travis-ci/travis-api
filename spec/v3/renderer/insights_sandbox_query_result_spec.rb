describe Travis::API::V3::Renderer::InsightsSandboxQueryResult do
  let(:object) { { 'negative_results' => [], 'positive_results' => ['test'], 'success' => true } }

  subject { Travis::API::V3::Renderer::InsightsSandboxQueryResult }

  describe "basic check" do
    it "returns a basic representation of the object" do
      expect(subject.render(object)).to eq(
        {
          '@type': 'insights_sandbox_query_result',
          negative_results: object['negative_results'],
          positive_results: object['positive_results'],
          success: object['success']
        }
      )
    end
  end

  describe '#available_attributes' do
    it 'returns available attributes' do
      expect(subject.available_attributes).to eq([:negative_results, :positive_results, :success])
    end
  end
end

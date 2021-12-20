describe Travis::API::V3::Renderer::InsightsSandboxPluginData do
  let(:object) { { 'key' => 'test', 'key2' => 'test' } }

  subject { Travis::API::V3::Renderer::InsightsSandboxPluginData }

  describe "basic check" do
    it "returns a basic representation of the object" do
      expect(subject.render(object)).to eq(
        {
          '@type': 'insights_sandbox_plugin_data',
          data: object
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

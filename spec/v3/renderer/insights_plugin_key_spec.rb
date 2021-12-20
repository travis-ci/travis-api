describe Travis::API::V3::Renderer::InsightsPluginKey do
  let(:object) { { 'keys' => ['test', 'test2'] } }

  subject { Travis::API::V3::Renderer::InsightsPluginKey }

  describe "basic check" do
    it "returns a basic representation of the object" do
      expect(subject.render(object)).to eq(
        {
          '@type': 'insights_plugin_key',
          keys: object['keys']
        }
      )
    end
  end

  describe '#available_attributes' do
    it 'returns available attributes' do
      expect(subject.available_attributes).to eq([:keys])
    end
  end
end

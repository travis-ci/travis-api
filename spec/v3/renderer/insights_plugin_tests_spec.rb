describe Travis::API::V3::Renderer::InsightsPluginTests do
  let(:object) { { 'template_tests' => { 'key' => 'test' }, 'plugin_category' => 'test' } }

  subject { Travis::API::V3::Renderer::InsightsPluginTests }

  describe "basic check" do
    it "returns a basic representation of the object" do
      expect(subject.render(object)).to eq(
        {
          '@type': 'insights_plugin_tests',
          template_tests: object['template_tests'],
          plugin_category: object['plugin_category']
        }
      )
    end
  end

  describe '#available_attributes' do
    it 'returns available attributes' do
      expect(subject.available_attributes).to eq([:template_tests, :plugin_category])
    end
  end
end

describe Travis::API::V3::Renderer::InsightsPluginAuthenticate do
  let(:object) { { 'success' => 'test', 'error_msg' => nil } }

  subject { Travis::API::V3::Renderer::InsightsPluginAuthenticate }

  describe "basic check" do
    it "returns a basic representation of the object" do
      expect(subject.render(object)).to eq(
        {
          '@type': 'insights_plugin_authenticate',
          success: object['success'],
          error_msg: object['error_msg']
        }
      )
    end
  end

  describe '#available_attributes' do
    it 'returns available attributes' do
      expect(subject.available_attributes).to eq([:success, :error_msg])
    end
  end
end

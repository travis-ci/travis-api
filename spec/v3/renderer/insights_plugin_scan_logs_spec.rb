describe Travis::API::V3::Renderer::InsightsPluginScanLogs do
  let(:object) { { 'meta' => { 'key' => 'test' }, 'scan_logs' => ['test', 'test2'] } }

  subject { Travis::API::V3::Renderer::InsightsPluginScanLogs }

  describe "basic check" do
    it "returns a basic representation of the object" do
      expect(subject.render(object)).to eq(
        {
          '@type': 'insights_plugin_scan_logs',
          meta: object['meta'],
          scan_logs: object['scan_logs']
        }
      )
    end
  end

  describe '#available_attributes' do
    it 'returns available attributes' do
      expect(subject.available_attributes).to eq([:meta, :scan_logs])
    end
  end
end

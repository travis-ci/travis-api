describe Travis::API::V3::Renderer::InsightsSandboxPlugins do
  let(:object) { { 'in_progress' => false, 'no_plugins' => false, 'plugins' => ['test'] } }

  subject { Travis::API::V3::Renderer::InsightsSandboxPlugins }

  describe "basic check" do
    it "returns a basic representation of the object" do
      expect(subject.render(object)).to eq(
        {
          '@type': 'insights_sandbox_plugins',
          plugins: object['plugins'],
          in_progress: object['in_progress'],
          no_plugins: object['no_plugins']
        }
      )
    end
  end

  describe '#available_attributes' do
    it 'returns available attributes' do
      expect(subject.available_attributes).to eq([:plugins, :in_progress, :no_plugins])
    end
  end
end

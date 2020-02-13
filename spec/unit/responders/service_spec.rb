describe Travis::Api::App::Responders::Service do
  class MyService < Travis::Api::App::Responders::Service
  end

  let(:endpoint) { double 'endpoint', public?: true }
  let(:resource) { double 'resource', run: {} }
  let(:options)  { {} }
  let(:service)  { MyService.new(endpoint, resource, options) }

  context 'with final resource' do
    before { allow(resource).to receive(:final?).and_return(true) }

    it 'caches resource for a year' do
      expect(endpoint).to receive(:expires).with(31536000, :public)
      service.apply
    end
  end

end

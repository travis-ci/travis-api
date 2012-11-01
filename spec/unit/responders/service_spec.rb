require 'spec_helper'

describe Travis::Api::App::Responders::Service do
  class MyService < Travis::Api::App::Responders::Service
  end

  let(:endpoint) { stub 'endpoint', public?: true }
  let(:resource) { stub 'resource', run: {} }
  let(:options)  { {} }
  let(:service)  { MyService.new(endpoint, resource, options) }

  context 'with final resource' do
    before { resource.expects(:final?).returns(true) }

    it 'caches resource for a year' do
      endpoint.expects(:expires).with(31536000, :public)
      service.apply
    end
  end

end

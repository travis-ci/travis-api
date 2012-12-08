require 'spec_helper'

module Travis::Api::App::Responders
  describe Json do
    class MyJson < Json
    end

    let(:request)  { stub 'request', accept: ['application/vnd.travis-ci.2+json'], params: {} }
    let(:endpoint) { stub 'endpoint', request: request }
    let(:resource) { stub 'resource' }
    let(:options)  { {} }
    let(:json)  { MyJson.new(endpoint, resource, options) }

    context 'with resource not associated with Api data class' do
      it 'returns nil result' do
        json.expects(:halt).with(404)
        json.apply
      end
    end

    context 'with resource being' do
      context 'a Hash instance' do
        let(:resource) { { foo: 'bar' } }

        it 'returns resource converted to_json' do
          json.expects(:halt).with({ foo: 'bar' }.to_json)
          json.apply
        end
      end

      context 'nil' do
        let(:resource) { nil }

        it 'responds with 404' do
          json.expects(:halt).with(404)
          json.apply
        end
      end
    end

    context 'with resource associated with Api data class' do
      let(:builder)       { stub 'builder', data: { foo: 'bar' } }
      let(:builder_class) { stub 'builder class', new: builder }
      before do
        json.stubs :builder => builder_class
      end

      it 'returns proper data converted to json' do
        json.expects(:halt).with({ foo: 'bar' }.to_json)
        json.apply
      end
    end
  end
end

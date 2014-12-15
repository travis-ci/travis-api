require 'spec_helper'

module Travis::Api::App::Responders
  describe Json do
    class MyJson < Json
    end

    let(:request)  { stub 'request', params: {} }
    let(:endpoint) { stub 'endpoint', request: request, content_type: nil  }
    let(:resource) { stub 'resource' }
    let(:accept)   { stub 'accept entry', version: '2', params: {} }
    let(:options)  { { :accept => accept} }
    let(:json)  { MyJson.new(endpoint, resource, options) }

    context 'with resource not associated with Api data class' do
      it 'returns nil result' do
        json.apply.should be_nil
      end
    end

    context 'with resource being' do
      context 'a Hash instance' do
        let(:resource) { { foo: 'bar' } }

        it 'returns resource converted to_json' do
          json.apply.should == { foo: 'bar' }
        end
      end

      context 'nil' do
        let(:resource) { nil }

        it 'responds with 404' do
          json.apply?.should be_falsey
          json.apply.should be_falsey
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
        json.apply.should == { foo: 'bar' }
      end
    end
  end
end

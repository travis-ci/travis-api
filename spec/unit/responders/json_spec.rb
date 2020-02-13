module Travis::Api::App::Responders
  describe Json do
    class MyJson < Json
    end

    let(:request)  { double 'request', params: {} }
    let(:endpoint) { double 'endpoint', request: request, content_type: nil  }
    let(:resource) { double 'resource' }
    let(:accept)   { double 'accept entry', version: '2', params: {} }
    let(:options)  { { :accept => accept} }
    let(:json)  { MyJson.new(endpoint, resource, options) }

    context 'with resource not associated with Api data class' do
      it 'returns nil result' do
        expect(json.apply).to be_nil
      end
    end

    context 'with resource being' do
      context 'a Hash instance' do
        let(:resource) { { foo: 'bar' } }

        it 'returns resource converted to_json' do
          expect(json.apply).to eq({ foo: 'bar' })
        end
      end

      context 'nil' do
        let(:resource) { nil }

        it 'responds with 404' do
          expect(json.apply?).to be_falsey
          expect(json.apply).to be_falsey
        end
      end
    end

    context 'with resource associated with Api data class' do
      let(:builder)       { double 'builder', data: { foo: 'bar' } }
      let(:builder_class) { double 'builder class', new: builder }
      before do
        allow(json).to receive(:builder).and_return(builder_class)
      end

      it 'returns proper data converted to json' do
        expect(json.apply).to eq({ foo: 'bar' })
      end
    end
  end
end

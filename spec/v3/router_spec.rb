describe Travis::API::V3::Router, set_app: true do
  describe '#call' do
    let(:env) do
      {
        'PATH_INFO' => '/',
        'rack.request.query_hash' => {},
      }
    end

    context 'when user has no perms' do
      before { env['HTTP_AUTHORIZATION'] = 'Token 123' }

      it 'returns a 403 error' do
        expect(subject.call(env).first).to eq(403)
      end
    end

    context 'when user has perms' do
      before { env['rack.request.query_hash']['log.token'] = '123' }

      it 'returns a 200 response' do
        expect(subject.call(env).first).to eq(200)
      end
    end
  end
end

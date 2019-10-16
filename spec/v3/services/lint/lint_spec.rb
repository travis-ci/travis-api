describe Travis::API::V3::Services::Lint::Lint, set_app: true do
  let(:content) { 'foo: bar' }
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:body) { JSON.dump(full_messages: [msg]) }
  let(:msg) { '[warn] on root: unknown key "unknown" (str)' }

  before { stub_request(:post, 'https://yml.travis-ci.org/v1/parse').to_return(body: body) }

  describe 'accepts content in parameter' do
    before { post('v3/lint', content: content ) }
    it { expect(last_response).to be_ok }
    it do
      expect(parsed_body).to eql_json(
        '@type' =>  'lint',
        'warnings' => [
          {
            'key' => [],
            'message' => msg
          }
        ]
      )
    end
  end

  describe 'accepts content as body' do
    let(:headers) { { 'CONTENT_TYPE' => 'text/yaml' } }
    before { post('/v3/lint', content, headers) }
    it { expect(last_response).to be_ok }
    it do
      expect(parsed_body).to eql_json(
        '@type' =>  'lint',
        'warnings' => [
          {
            'key' => [],
            'message' => msg
          }
        ]
      )
    end
  end
end

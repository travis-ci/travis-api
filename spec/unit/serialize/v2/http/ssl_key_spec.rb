describe Travis::Api::Serialize::V2::Http::SslKey do
  include Travis::Testing::Stubs
  include Support::Formats

  let(:key) {
    key = stub_key
    allow(key).to receive(:private_key).and_return(TEST_PRIVATE_KEY)
    key
  }
  let(:data) { described_class.new(key).data }

  it 'returns data' do
    expect(data['key']).to eq('-----BEGIN PUBLIC KEY-----')
    expect(data['fingerprint']).to eq('57:78:65:c2:c9:c8:c9:f7:dd:2b:35:39:40:27:d2:40')
  end
end

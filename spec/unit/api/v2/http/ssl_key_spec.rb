require 'spec_helper'

describe Travis::Api::V2::Http::Repository do
  include Travis::Testing::Stubs
  include Support::Formats

  let(:key) {
    key = stub_key
    key.stubs(:private_key).returns(TEST_PRIVATE_KEY)
    key
  }
  let(:data) { Travis::Api::V2::Http::SslKey.new(key).data }

  it 'returns data' do
    data['key'].should == '-----BEGIN PUBLIC KEY-----'
    data['fingerprint'].should == '57:78:65:c2:c9:c8:c9:f7:dd:2b:35:39:40:27:d2:40'
  end
end

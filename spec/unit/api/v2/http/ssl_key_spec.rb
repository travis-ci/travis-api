require 'spec_helper'

describe Travis::Api::V2::Http::Repository do
  include Travis::Testing::Stubs
  include Support::Formats

  let(:data) { Travis::Api::V2::Http::SslKey.new(stub_key).data }

  it 'key' do
    data['key'].should == '-----BEGIN PUBLIC KEY-----'
  end
end

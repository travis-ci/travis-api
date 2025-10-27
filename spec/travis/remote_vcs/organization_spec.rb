require 'spec_helper'
require 'travis/remote_vcs/organization'

RSpec.describe Travis::RemoteVCS::Organization do
  let(:client) { described_class.new }
  let(:org_id) { '12345' }
  let(:subject) { client.destroy(org_id: org_id) }

  describe '#destroy' do
    it 'sends a delete request to the correct URL' do
      request = double('request')
      expect(request).to receive(:url).with("organizations/#{org_id}")
      expect(client).to receive(:request).with(:delete, :destroy, false).and_yield(request)
      subject
    end

    context 'when request is successful' do
      before { allow(client).to receive(:request).and_return(true) }
      it { is_expected.to be true }
    end

    context 'when the request fails' do
      before { allow(client).to receive(:request).and_return(false) }
      it { is_expected.to be false }
    end
  end
end

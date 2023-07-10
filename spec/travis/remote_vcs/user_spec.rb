# frozen_string_literal: true

require 'rspec'

describe Travis::RemoteVCS::User do
  describe '#confirm_user' do
    let(:token) { double(:token) }
    let(:instance) { described_class.new }
    let(:req) { double(:request) }
    let(:params) { double(:params) }

    subject { instance.confirm_user(token: token) }

    before do
      allow(req).to receive(:url)
      allow(req).to receive(:params).and_return(params)
      allow(params).to receive(:[]=)
    end

    it 'performs POST to VCS with proper params' do
      expect(instance).to receive(:request).with(:post, :confirm_user).and_yield(req)
      expect(req).to receive(:url).with('users/confirm')
      expect(params).to receive(:[]=).with('token', token)

      subject
    end
  end

  describe '#request_confirmation' do
    let(:id) { double(:id) }
    let(:instance) { described_class.new }
    let(:req) { double(:request) }
    let(:params) { double(:params) }

    subject { instance.request_confirmation(id: id) }

    before do
      allow(req).to receive(:url)
      allow(req).to receive(:params).and_return(params)
      allow(params).to receive(:[]=)
    end

    it 'performs POST to VCS with proper params' do
      expect(instance).to receive(:request).with(:post, :request_confirmation).and_yield(req)
      expect(req).to receive(:url).with('users/request_confirmation')
      expect(params).to receive(:[]=).with('id', id)

      subject
    end
  end

  describe '#authenticate' do
    let(:user) { described_class.new }
    let(:provider) { 'assembla' }
    let(:code) { '1234' }
    let(:redirect_uri) { 'test' }
    let(:cluster) { 'special' }
    let!(:request) do
      stub_request(:post, /\/users\/session\?cluster=#{cluster}&code=#{code}&provider=#{provider}&redirect_uri=#{redirect_uri}/)
        .to_return(
          status: 200,
          body: nil,
        )
    end

    before { Travis.config.vcs  = { url: 'http://vcs:3000', token: 'token' } }

    subject { user.authenticate(provider: provider, code: code, redirect_uri: redirect_uri, cluster: cluster) }

    it 'performs a proper request' do
      subject
      expect(request).to have_been_made
    end
  end
end

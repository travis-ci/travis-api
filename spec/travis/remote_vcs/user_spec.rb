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
    let(:session_token) { double(:session_token) }
    let(:instance) { described_class.new }
    let(:req) { double(:request) }
    let(:params) { double(:params) }

    subject { instance.request_confirmation(id: id, session_token: session_token) }

    before do
      allow(req).to receive(:url)
      allow(req).to receive(:params).and_return(params)
      allow(params).to receive(:[]=)
    end

    it 'performs POST to VCS with proper params' do
      expect(instance).to receive(:request).with(:post, :request_confirmation).and_yield(req)
      expect(req).to receive(:url).with('users/request_confirmation')
      expect(params).to receive(:[]=).with('id', id)
      expect(params).to receive(:[]=).with('session_token', session_token)

      subject
    end
  end
end

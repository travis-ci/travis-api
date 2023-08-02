# frozen_string_literal: true
require 'spec_helper'

describe Travis::RemoteVCS::Repository do
  let(:repository) { described_class.new }
  let(:id) { 2 }
  let(:user_id) { 1 }

  before { Travis.config.vcs  = { url: 'http://vcs:3000', token: 'token' } }

  describe '#keys' do
    let(:key) do
      { id: 1 }
    end
    let!(:request) do
      stub_request(:get, /\/repos\/#{id}\/keys\?user_id=#{user_id}/)
        .to_return(
          status: 200,
          body: JSON.dump([key]),
        )
    end

    subject { repository.keys(repository_id: id, user_id: user_id) }

    it 'performs a proper request' do
      expect(subject).to eq([key.stringify_keys])
      expect(request).to have_been_made
    end
  end

  describe '#create_perforce_group' do
    let!(:request) do
      stub_request(:post, /\/repos\/#{id}\/perforce_groups\?user_id=#{user_id}/)
        .to_return(
          status: 200,
          body: nil,
        )
    end

    subject { repository.create_perforce_group(repository_id: id, user_id: user_id) }

    it 'performs a proper request' do
      subject
      expect(request).to have_been_made
    end
  end

  describe '#delete_perforce_group' do
    let!(:request) do
      stub_request(:delete, /\/repos\/#{id}\/perforce_groups\?user_id=#{user_id}/)
        .to_return(
          status: 200,
          body: nil,
        )
    end

    subject { repository.delete_perforce_group(repository_id: id, user_id: user_id) }

    it 'performs a proper request' do
      subject
      expect(request).to have_been_made
    end
  end

  describe '#set_perforce_ticket' do
    let(:token) { '1235' }
    let!(:request) do
      stub_request(:post, /\/repos\/#{id}\/perforce_ticket\?user_id=#{user_id}/)
        .to_return(
          status: 200,
          body: JSON.dump(token: token),
        )
    end

    subject { repository.set_perforce_ticket(repository_id: id, user_id: user_id) }

    it 'performs a proper request' do
      expect(subject).to eq('token' => token)
      expect(request).to have_been_made
    end
  end
end

require 'rails_helper'

describe Services::User::ConfirmUser do

  context '#call' do
    subject { instance.call  }

    let(:instance) { described_class.new(user) }
    let(:user) { instance_double(User) }
    let(:vcs) { double(:vcs) }
    let(:token) { 'token' }

    before do
      allow(user).to receive(:confirmation_token).and_return(token)
      allow(instance).to receive(:vcs).and_return(vcs)
      allow(vcs).to receive(:post).and_yield(vcs)
      allow(vcs).to receive(:body=)
    end

    it 'calls VCS endpoint' do
      subject

      expect(vcs).to have_received(:body=).with({ token: 'token' }.to_json)
    end
  end
end

require 'rails_helper'

describe Services::User::SendConfirmationEmail do

  context '#call' do
    subject { instance.call  }

    let(:instance) { described_class.new(user) }
    let(:user) { instance_double(User, id: 1) }
    let(:vcs) { double(:vcs) }
    let(:token) { 'token' }

    before do
      allow(instance).to receive(:vcs).and_return(vcs)
      allow(vcs).to receive(:post).and_yield(vcs)
      allow(vcs).to receive(:body=)
    end

    it 'calls VCS endpoint' do
      subject

      expect(vcs).to have_received(:body=).with({ id: 1 }.to_json)
    end
  end
end

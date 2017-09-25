require 'rails_helper'

RSpec.describe Services::JobBoost::Update do
  let!(:user)          { create(:user, id: 162, login: 'lisbethmarianne', name: 'Katrin', email: 'katrin@example.com') }

  let(:job_boost) { Services::JobBoost::Update.new(user.login, user) }

  describe 'Job boost' do
    it 'notify Slack about' do
      expect(job_boost).to receive(:call)
      job_boost.call(10,1)
    end
  end
end

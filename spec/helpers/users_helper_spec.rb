require 'rails_helper'

RSpec.describe UsersHelper, type: :helper do
  describe '#hidden' do
    let(:user) { build :user, github_oauth_token: '3k0Tjf#kdls'}

    it 'replaces all characters with *' do
      expect(helper.hidden(user, :github_oauth_token)).to eq('***********')
    end
  end
end

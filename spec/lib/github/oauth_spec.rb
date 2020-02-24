describe Travis::Github::Oauth do
  let(:user) { FactoryBot.create(:user, github_oauth_token: 'token', github_scopes: scopes) }

  describe 'correct_scopes?' do
    let(:scopes) { ['public_repo', 'user:email'] }
    subject { described_class.correct_scopes?(user) }

    it 'accepts correct scopes' do
      should eq true
    end

    it 'complains about missing scopes' do
      user.github_scopes.pop
      should eq false
    end

    it 'accepts additional scopes' do
      user.github_scopes << 'foo'
      should eq true
    end
  end

  describe 'update_scopes' do
    before { user.reload }

    describe 'the token did not change' do
      let(:scopes) { ['public_repo', 'user:email'] }

      it 'does not resolve github scopes' do
        expect(Travis::Github::Oauth).not_to receive(:scopes_for)
        described_class.update_scopes(user)
      end
    end

    describe 'the token has changed' do
      let(:scopes) { ['public_repo', 'user:email'] }

      before do
        user.github_oauth_token = 'changed'
        user.save!
      end

      it 'updates github scopes' do
        expect(Travis::Github::Oauth).to receive(:scopes_for).and_return(['foo', 'bar'])
        described_class.update_scopes(user)
        expect(user.reload.github_scopes).to eq ['foo', 'bar']
      end
    end

    describe 'no scopes have been set so far' do
      let(:scopes) { nil }

      before do
        user.github_oauth_token = 'changed'
        user.save!
      end

      it 'updates github scopes' do
        expect(Travis::Github::Oauth).to receive(:scopes_for).and_return(['foo', 'bar'])
        described_class.update_scopes(user)
        expect(user.reload.github_scopes).to eq ['foo', 'bar']
      end
    end
  end
end

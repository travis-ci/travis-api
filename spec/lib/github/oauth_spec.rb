describe Travis::Github::Oauth do
  let(:user) { Factory(:user, github_oauth_token: 'token', github_scopes: scopes) }
  let(:scopes) { ["read:org",
                  "user:email",
                  "public_repo",
                  "repo_deployment",
                  "repo:status",
                  "write:repo_hook"
                ] }

  describe 'correct_scopes?' do
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
      it 'does not resolve github scopes' do
        Travis::Github::Oauth.expects(:scopes_for).never
        described_class.update_scopes(user)
      end
    end

    describe 'the token has changed' do
      before do
        user.github_oauth_token = 'changed'
        user.save!
      end

      it 'updates github scopes' do
        Travis::Github::Oauth.expects(:scopes_for).returns(['foo', 'bar'])
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
        Travis::Github::Oauth.expects(:scopes_for).returns(['foo', 'bar'])
        described_class.update_scopes(user)
        expect(user.reload.github_scopes).to eq ['foo', 'bar']
      end
    end
  end
end

describe User do
  before { DatabaseCleaner.clean_with :truncation }

  let(:user)    { FactoryBot.create(:user, :github_oauth_token => 'token') }
  let(:payload) { GITHUB_PAYLOADS[:oauth] }

  describe 'find_or_create_for_oauth' do
    def user(payload)
      User.find_or_create_for_oauth(payload)
    end

    it 'marks new users as such' do
      expect(user(payload)).to be_recently_signed_up
      expect(user(payload)).not_to be_recently_signed_up
    end

    it 'updates changed attributes' do
      expect(user(payload).attributes.slice(*GITHUB_OAUTH_DATA.keys)).to eq(GITHUB_OAUTH_DATA)
    end
  end

  describe '#to_json' do
    it 'returns JSON representation of user' do
      json = JSON.parse(user.to_json)
      expect(json['user']['login']).to eq('svenfuchs')
    end
  end

  describe 'permission?' do
    let!(:repo) { FactoryBot.create(:org, :login => 'travis') }

    it 'given roles and a condition it returns true if the user has a matching permission for this role' do
      user.permissions.create!(push: true, repository_id: repo.id)
      expect(user.permission?(['push'], repository_id: repo.id)).to be true
    end

    it 'given roles and a condition it returns false if the user does not have a matching permission for this role' do
      user.permissions.create!(pull: true, repository_id: repo.id)
      expect(user.permission?(['push'], repository_id: repo.id)).to be false
    end

    it 'given a condition it returns true if the user has a matching permission' do
      user.permissions.create!(push: true, repository_id: repo.id)
      expect(user.permission?(repository_id: repo.id)).to be true
    end

    it 'given a condition it returns true if the user has a matching permission' do
      expect(user.permission?(repository_id: repo.id)).to be false
    end
  end

  describe 'organization_ids' do
    let!(:travis)  { FactoryBot.create(:org, :login => 'travis') }
    let!(:sinatra) { FactoryBot.create(:org, :login => 'sinatra') }

    before :each do
     user.organizations << travis
     user.save!
    end

    it 'contains the ids of organizations that the user is a member of' do
      expect(user.organization_ids).to include(travis.id)
    end

    it 'does not contain the ids of organizations that the user is not a member of' do
      expect(user.organization_ids).not_to include(sinatra.id)
    end
  end

  describe 'repository_ids' do
    let!(:travis)  { FactoryBot.create(:repository, :name => 'travis', :owner => FactoryBot.create(:org, :name => 'travis')) }
    let!(:sinatra) { FactoryBot.create(:repository, :name => 'sinatra', :owner => FactoryBot.create(:org, :name => 'sinatra')) }

    before :each do
     user.repositories << travis
     user.save!
     user.reload
    end

    it 'contains the ids of repositories the user is permitted to see' do
      expect(user.repository_ids).to include(travis.id)
    end

    it 'does not contain the ids of repositories the user is not permitted to see' do
      expect(user.repository_ids).not_to include(sinatra.id)
    end
  end

  describe 'avatar_url' do
    it "returns avatar url if it's present" do
      user.avatar_url = 'foo'
      expect(user.avatar_url).to eq('foo')
    end

    it "returns gravatar url if avatar url is not present, but gravatar_id is" do
      user.avatar_url = nil
      user.gravatar_id = 'foo'
      expect(user.avatar_url).to eq('https://0.gravatar.com/avatar/foo')
    end

    it "returns gravatar url based on the e-mail if both avatar_url and gravatar_id are nil" do
      user.avatar_url = nil
      user.gravatar_id = nil
      expect(user.avatar_url).to eq('https://0.gravatar.com/avatar/07fb84848e68b96b69022d333ca8a3e2')
    end
  end

  describe 'profile_image_hash' do
    it "returns gravatar_id if it's present" do
      user.gravatar_id = '41193cdbffbf06be0cdf231b28c54b18'
      expect(user.profile_image_hash).to eq('41193cdbffbf06be0cdf231b28c54b18')
    end

    it 'returns a MD5 hash of the email if no gravatar_id and an email is set' do
      user.gravatar_id = nil
      expect(user.profile_image_hash).to eq(Digest::MD5.hexdigest(user.email))
    end

    it 'returns 32 zeros if no gravatar_id or email is set' do
      user.gravatar_id = nil
      user.email = nil
      expect(user.profile_image_hash).to eq('0' * 32)
    end
  end

  describe 'service_hooks' do
    let(:own_repo)   { FactoryBot.create(:repository, :name => 'own-repo', :description => 'description', :active => true) }
    let(:admin_repo) { FactoryBot.create(:repository, :name => 'admin-repo') }
    let(:other_repo) { FactoryBot.create(:repository, :name => 'other-repo') }
    let(:push_repo) { FactoryBot.create(:repository, :name => 'push-repo') }

    before :each do
      user.permissions.create! :user => user, :repository => own_repo, :admin => true
      user.permissions.create! :user => user, :repository => admin_repo, :admin => true
      user.permissions.create! :user => user, :repository => push_repo, :push => true
      other_repo
    end

    it "contains repositories where the user has an admin role" do
      expect(user.service_hooks).to include(own_repo)
    end

    it "does not contain repositories where the user does not have an admin role" do
      expect(user.service_hooks).not_to include(other_repo)
    end

    it "includes all repositories if :all options is passed" do
      hooks = user.service_hooks(:all => true)
      expect(hooks).to include(own_repo)
      expect(hooks).to include(push_repo)
      expect(hooks).to include(admin_repo)
      expect(hooks).not_to include(other_repo)
    end
  end

  describe 'github_scopes' do
    it 'returns an empty list if the token is missing' do
      user.github_scopes = ['foo']
      user.github_oauth_token = nil
      expect(user.github_scopes).to be_empty
    end
  end

  describe 'inspect' do
    context 'when user has GitHub OAuth token' do
      before :each do
        user.github_oauth_token = 'foobarbaz'
      end

      it 'does not include the user\'s GitHub OAuth token' do
        expect(user.inspect).not_to include('foobarbaz')
      end
    end

    context 'when user has no GitHub OAuth token' do
      before :each do
        user.github_oauth_token = nil
      end

      it 'indicates nil GitHub OAuth token' do
        expect(user.inspect).to include('github_oauth_token: nil')
      end
    end
  end

  describe 'tokens' do
    let(:user) { FactoryBot.create(:user) }

    it 'creates two tokens on creation' do
      expect(user.tokens.asset.count).to eq(1)
      expect(user.tokens.rss.count).to eq(1)
    end
  end

  describe '#preferences' do
    it 'keeps them as ruby hash' do
      user.preferences = { 'a' => 'b', 'c' => 'd' }.to_json
      user.save!

      expect(user.reload.preferences).to be_a(Hash)

      user.preferences = { 'a' => 'b', 'c' => 'd' }
      user.save!

      expect(user.reload.preferences).to be_a(Hash)
    end
  end
end

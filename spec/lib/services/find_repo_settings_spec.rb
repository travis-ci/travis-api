describe Travis::Services::FindRepoSettings do
  let(:repo)    { FactoryBot.create(:repository_without_last_build) }
  let(:params)  { { id: repo.id } }
  let(:user)    { FactoryBot.create(:user) }
  let(:service) { described_class.new(user, params) }

  before do
    repo.settings.merge('build_pushes' => false)
    repo.settings.save
    repo.save
  end

  describe 'authorized?' do
    let(:service) { described_class.new(nil, params) }

    it 'should be unauthorized with current_user' do
      expect(service).not_to be_authorized
    end
  end

  describe 'run' do
    it 'should return nil without a repo' do
      repo.destroy
      expect(service.run).to be_nil
    end

    it 'should return repo settings' do
      user.permissions.create(repository_id: repo.id, push: true)
      expect(service.run.to_hash).to eq(repo.settings.to_hash)
    end

    it 'should not be able to get settings if user does not have push permission' do
      user.permissions.create(repository_id: repo.id, push: false)

      expect(service.run).to be_nil
    end
  end
end


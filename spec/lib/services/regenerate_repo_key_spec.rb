describe Travis::Services::RegenerateRepoKey do
  let(:user)    { User.first || FactoryBot.create(:user) }
  let!(:repo)   { FactoryBot.create(:repository, :owner_name => 'travis-ci', :name => 'travis-core') }
  let(:service) { described_class.new(user, :id => repo.id) }

  before :each do
    expect(service).to receive(:service).with(:find_repo, {id: repo.id}).and_return(double(:run => repo))
    user.permissions.create!(:repository_id => repo.id, :admin => true)
  end

  describe 'given the request is authorized' do
    it 'regenerates the key' do
      expect(repo).to receive(:regenerate_key!)
      expect(service.run).to eq(repo.reload.key)
    end
  end

  describe 'given the request is not authorized' do
    it 'does not regenerate key' do
      user.permissions.destroy_all
      expect(repo).not_to receive(:regenerate_key!)
      expect(service.run).to be_falsey
    end
  end
end

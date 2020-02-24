describe Travis::Services::FindBranch do
  let(:user)    { FactoryBot.create(:user) }
  let(:repo)    { FactoryBot.create(:repository, :owner_name => 'travis-ci', :name => 'travis-core') }
  let!(:build)  { FactoryBot.create(:build, :repository => repo, :state => :finished) }
  let(:service) { described_class.new(user, params) }

  attr_reader :params

  it 'finds the last builds of the given repository and branch' do
    @params = { :repository_id => repo.id, :branch => 'master' }
    expect(service.run).to eq(build)
  end

  it 'scopes to the given repository' do
    @params = { :repository_id => repo.id, :branch => 'master' }
    build = FactoryBot.create(:build, :repository => FactoryBot.create(:repository), :state => :finished)
    expect(service.run).not_to eq(build)
  end

  it 'returns an empty build scope when the repository could not be found' do
    @params = { :repository_id => repo.id + 1, :branch => 'master' }
    expect(service.run).to be_nil
  end

  it 'finds branches by a given id' do
    @params = { :id => build.id }
    expect(service.run).to eq(build)
  end
end

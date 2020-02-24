describe Travis::Services::FindUserAccounts do
  let!(:sven)    { FactoryBot.create(:user, id: 9999999, :login => 'sven') }
  let!(:travis)  { FactoryBot.create(:org, :login => 'travis-ci') }
  let!(:sinatra) { FactoryBot.create(:org, :login => 'sinatra') }
  let!(:non_user_org) { FactoryBot.create(:org, :login => 'travis-ci') }

  let!(:repos) do
    [
      FactoryBot.create(:repository, :owner => sven, :owner_name => 'sven', :name => 'minimal'),
      FactoryBot.create(:repository, :owner => travis, :owner_name => 'travis-ci', :name => 'travis-ci'),
      FactoryBot.create(:repository, :owner => travis, :owner_name => 'travis-ci', :name => 'travis-core'),
      FactoryBot.create(:repository, :owner => sinatra, :owner_name => 'sinatra', :name => 'sinatra'),
    ]
  end

  let!(:repo_without_permissions) {
    FactoryBot.create(:repository, :owner => travis, :owner_name => 'travis-ci', :name => 'secret')
  }

  let!(:org) { FactoryBot.create(:org, id: sven.id) }

  let(:service) { described_class.new(sven, params || {}) }

  attr_reader :params

  before :each do
    repos.each do |repo|
      permissions = repo.name == 'sinatra' ? { :push => true } : { :admin => true }
      sven.permissions.create!(permissions.merge :repository => repo)
    end

    sven.organizations << travis
  end

  it 'includes all repositories with :all param' do
    @params = { all: true }
    expect(service.run).to include(Account.from(sven), Account.from(travis), Account.from(sinatra))
  end

  it 'includes the user' do
    expect(service.run).to include(Account.from(sven))
  end

  it 'includes accounts where the user has admin access' do
    expect(service.run).to include(Account.from(travis))
  end

  it 'does not include accounts where the user does not have admin access' do
    expect(service.run).not_to include(Account.from(sinatra))
  end

  it 'does not include account of organizations that do not belong to the user, even though they match by name' do
    expect(service.run).not_to include(Account.from(non_user_org))
  end

  it 'does not include organizations with the same id as a user' do
    expect(service.run).not_to include(Account.from(org))
  end

  it 'includes repository counts' do
    expect(service.run.map(&:repos_count)).to eq([1, 2])
  end

  it 'works when user doesn\'t have any repos' do
    Permission.destroy_all

    expect(service.run).to include(Account.from(sven))
  end
end

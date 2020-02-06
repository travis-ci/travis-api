describe Travis::Services::FindUserAccounts do
  let!(:sven)    { FactoryGirl.create(:user, id: 9999999, :login => 'sven') }
  let!(:travis)  { FactoryGirl.create(:org, :login => 'travis-ci') }
  let!(:sinatra) { FactoryGirl.create(:org, :login => 'sinatra') }
  let!(:non_user_org) { FactoryGirl.create(:org, :login => 'travis-ci') }

  let!(:repos) do
    [
      FactoryGirl.create(:repository, :owner => sven, :owner_name => 'sven', :name => 'minimal'),
      FactoryGirl.create(:repository, :owner => travis, :owner_name => 'travis-ci', :name => 'travis-ci'),
      FactoryGirl.create(:repository, :owner => travis, :owner_name => 'travis-ci', :name => 'travis-core'),
      FactoryGirl.create(:repository, :owner => sinatra, :owner_name => 'sinatra', :name => 'sinatra'),
    ]
  end

  let!(:repo_without_permissions) {
    FactoryGirl.create(:repository, :owner => travis, :owner_name => 'travis-ci', :name => 'secret')
  }

  let!(:org) { FactoryGirl.create(:org, id: sven.id) }

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
    service.run.should include(Account.from(sven), Account.from(travis), Account.from(sinatra))
  end

  it 'includes the user' do
    service.run.should include(Account.from(sven))
  end

  it 'includes accounts where the user has admin access' do
    service.run.should include(Account.from(travis))
  end

  it 'does not include accounts where the user does not have admin access' do
    service.run.should_not include(Account.from(sinatra))
  end

  it 'does not include account of organizations that do not belong to the user, even though they match by name' do
    service.run.should_not include(Account.from(non_user_org))
  end

  it 'does not include organizations with the same id as a user' do
    service.run.should_not include(Account.from(org))
  end

  it 'includes repository counts' do
    service.run.map(&:repos_count).should == [1, 2]
  end

  it 'works when user doesn\'t have any repos' do
    Permission.destroy_all

    service.run.should include(Account.from(sven))
  end
end

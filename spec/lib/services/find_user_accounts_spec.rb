describe Travis::Services::FindUserAccounts do
  let!(:sven)    { Factory(:user, :login => 'sven') }
  let!(:travis)  { Factory(:org, :login => 'travis-ci') }
  let!(:sinatra) { Factory(:org, :login => 'sinatra') }
  let!(:non_user_org) { Factory(:org, :login => 'travis-ci') }

  let!(:repos) do
    Factory(:repository, :owner => sven, :owner_name => 'sven', :name => 'minimal')
    Factory(:repository, :owner => travis, :owner_name => 'travis-ci', :name => 'travis-ci')
    Factory(:repository, :owner => travis, :owner_name => 'travis-ci', :name => 'travis-core')
    Factory(:repository, :owner => sinatra, :owner_name => 'sinatra', :name => 'sinatra')
  end

  let(:service) { described_class.new(sven, params || {}) }

  attr_reader :params

  before :each do
    Repository.all.each do |repo|
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

  it 'includes repository counts' do
    service.run.map(&:repos_count).should == [1, 2]
  end
end

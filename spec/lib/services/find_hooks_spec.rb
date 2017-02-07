describe Travis::Services::FindHooks do
  let(:user)    { User.first || Factory(:user) }
  let(:repo)    { Factory(:repository) }
  let(:push_repo) { Factory(:repository, name: 'push-repo') }
  let(:service) { described_class.new(user, params) }

  before :each do
    user.permissions.create!(:repository => repo, :admin => true)
    user.permissions.create!(:repository => push_repo, :push => true)
  end

  attr_reader :params

  it 'finds repositories where the current user has access with :all option' do
    @params = { all: true }
    hooks = service.run
    hooks.should include(repo)
    hooks.should include(push_repo)
    expect(hooks.size).to eq(2)

    # hooks should include admin information
    hooks.sort_by(&:id).map(&:admin?).should == [true, false]
  end

  it 'does not order the repos with order=none' do
    first = Factory(:repository, name: 'abc')
    last = Factory(:repository, name: 'zyx')

    user.permissions.create!(:repository => first, :admin => true)
    user.permissions.create!(:repository => last,  :admin => true)

    @params = { all: true }
    service = described_class.new(user, params)
    hooks = service.run
    ordered_names = hooks.map(&:name).sort
    hooks.map(&:name).should == ordered_names

    @params = { all: true, order: 'none' }
    service = described_class.new(user, params)
    hooks = service.run
    ordered_names = hooks.map(&:name).sort
    hooks.map(&:name).should_not == ordered_names
  end



  it 'finds repositories where the current user has admin access' do
    @params = {}
    service.run.should include(repo)
  end

  it 'does not find repositories where the current user does not have admin access' do
    @params = {}
    user.permissions.delete_all
    service.run.should_not include(repo)
  end

  it 'finds repositories by a given owner_name where the current user has admin access' do
    @params = { :owner_name => repo.owner_name }
    service.run.should include(repo)
  end

  it 'does not find repositories by a given owner_name where the current user does not have admin access' do
    @params = { :owner_name => 'rails' }
    service.run.should_not include(repo)
  end
end

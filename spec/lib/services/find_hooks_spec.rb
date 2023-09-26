describe Travis::Services::FindHooks do
  let(:user)    { User.first || FactoryBot.create(:user) }
  let(:repo)    { FactoryBot.create(:repository) }
  let(:push_repo) { FactoryBot.create(:repository, name: 'push-repo') }
  let(:service) { described_class.new(user, params) }

  before :each do
    user.permissions.create!(:repository => repo, :admin => true)
    user.permissions.create!(:repository => push_repo, :push => true)
  end

  attr_reader :params

  it 'finds repositories where the current user has access with :all option' do
    @params = { all: true }
    hooks = service.run
    expect(hooks).to include(repo)
    expect(hooks).to include(push_repo)
    expect(hooks.size).to eq(2)
  end

  it 'does not order the repos with order=none' do
    first = FactoryBot.create(:repository, name: 'abc')
    last = FactoryBot.create(:repository, name: 'zyx')

    user.permissions.create!(:repository => first, :admin => true)
    user.permissions.create!(:repository => last,  :admin => true)

    @params = { all: true }
    service = described_class.new(user, params)
    hooks = service.run
    ordered_names = hooks.map(&:name).sort
    expect(hooks.map(&:name)).to eq(ordered_names)

    @params = { all: true, order: 'none' }
    service = described_class.new(user, params)
    hooks = service.run
    ordered_names = hooks.map(&:name).sort
    expect(hooks.map(&:name)).not_to eq(ordered_names)
  end



  it 'finds repositories where the current user has admin access' do
    @params = {}
    expect(service.run).to include(repo)
  end

  it 'does not find repositories where the current user does not have admin access' do
    @params = {}
    user.permissions.delete_all
    expect(service.run).not_to include(repo)
  end

  it 'finds repositories by a given owner_name where the current user has admin access' do
    @params = { :owner_name => repo.owner_name }
    expect(service.run).to include(repo)
  end

  it 'does not find repositories by a given owner_name where the current user does not have admin access' do
    @params = { :owner_name => 'rails' }
    expect(service.run).not_to include(repo)
  end
end

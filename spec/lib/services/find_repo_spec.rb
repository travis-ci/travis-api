describe Travis::Services::FindRepo do

  let(:user) { Factory(:user) }
  let!(:repo)   { Factory(:repository, :owner => user, :owner_name => 'travis-ci', :name => 'travis-core') }
  let(:service) { described_class.new(user, params) }


  attr_reader :params

  before :each do
    user.permissions.create!(admin: true, push: true, repository_id: repo.id)
  end

  describe 'run' do
    it 'finds a repository by the given id' do
      @params = { :id => repo.id }
      service.run.should == repo
    end

    it 'finds a repository by the given owner_name and name' do
      @params = { :owner_name => repo.owner_name, :name => repo.name }
      service.run.should == repo
    end

    it 'does not raise if the repository could not be found' do
      @params = { :id => repo.id + 1 }
      lambda { service.run }.should_not raise_error
    end
  end

  describe 'updated_at' do
    it 'returns jobs updated_at attribute' do
      @params = { :id => repo.id }
      service.updated_at.to_s.should == repo.updated_at.to_s
    end
  end
end

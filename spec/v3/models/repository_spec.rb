describe Travis::API::V3::Models::Repository do
  before { ActiveRecord::Base.connection.execute('truncate table branches cascade') }

  let(:repository) { described_class.find(Factory(:repository_without_last_build, default_branch: 'main').id) }

  def without_set_unique_name_trigger
    c = ActiveRecord::Base.connection

    c.execute("set set_unique_name_on_branches.disable = 't';")
    result = yield
    c.execute("set set_unique_name_on_branches.disable = 'f';")
    result
  end

  describe 'branch' do
    it 'chooses a branch with unique_name if there is a duplicate' do
      # create 2 branches without a unique_name and one with unique_name
      without_set_unique_name_trigger { FactoryGirl.create(:branch, repository_id: repository.id, name: 'main') }
      branch = FactoryGirl.create(:branch, repository_id: repository.id, name: 'main')
      without_set_unique_name_trigger { FactoryGirl.create(:branch, repository_id: repository.id, name: 'main') }

      repository.branch('main').should == branch
    end
  end
end


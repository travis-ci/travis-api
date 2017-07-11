describe Travis::Services::FindRequests do
  let(:user) { Factory(:user) }
  let(:repo) { Factory(:repository, :owner_name => 'travis-ci', :name => 'travis-core') }
  let!(:request)  { Factory(:request, :repository => repo) }
  let!(:newer_request)  { Factory(:request, :repository => repo) }
  let(:service) { described_class.new(user, params) }

  attr_reader :params

  describe 'run' do
    it 'finds recent requests when older_than is not given' do
      @params = { :repository_id => repo.id }
      service.run.should == [newer_request, request]
    end

    it 'includes the build_id' do
      Factory.create(:build, request_id: request.id)
      @params = { :repository_id => repo.id }
      requests = service.run
      requests.should == [newer_request, request]
      requests.first.build_id  = nil
      requests.second.build_id = request.builds.first.id
    end

    it 'finds requests older than the given id' do
      @params = { :repository_id => repo.id, :older_than => newer_request.id }
      service.run.should == [request]
    end

    it 'raises an error if repository params are missing' do
      @params = { }
      expect {
        service.run
      }.to raise_error(Travis::Api::App::RepositoryNotFoundError, "Repository could not be found")
    end

    it 'scopes to the given repository_id' do
      @params = { :repository_id => repo.id }
      Factory(:request, :repository => Factory(:repository))
      service.run.should == [newer_request, request]
    end

    it 'raises when the repository could not be found' do
      @params = { :repository_id => repo.id + 1 }
      expect {
        service.run
      }.to raise_error(Travis::Api::App::RepositoryNotFoundError, "Repository with id=#{repo.id + 1} could not be found")
    end

    it 'limits requests if limit is passed' do
      @params = { :repository_id => repo.id, :limit => 1 }
      service.run.should == [newer_request]
    end

    it 'limits requests to Travis.config.services.find_requests.max_limit if limit is higher' do
      Travis.config.services.find_requests.max_limit = 1
      @params = { :repository_id => repo.id, :limit => 2 }
      service.run.should == [newer_request]
    end

    it 'limits requests to Travis.config.services.find_requests.default_limit if limit is not given' do
      Travis.config.services.find_requests.default_limit = 1
      @params = { :repository_id => repo.id }
      service.run.should == [newer_request]
    end
  end
end

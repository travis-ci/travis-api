describe Request do
  let(:repo)         { Repository.new(owner_name: 'travis-ci', name: 'travis-core') }
  let(:commit)       { Commit.new(commit: '12345678') }
  let(:request)      { Request.new(repository: repo, commit: commit, pull_request: pull_request) }
  let(:pull_request) { nil }

  describe 'config_url' do
    before :each do
      GH.options.delete(:api_url)
      GH.current = nil
    end

    after :each do
      GH.set api_url: nil
    end

    it 'returns the api url to the .travis.yml file on github' do
      request.config_url.should == 'https://api.github.com/repos/travis-ci/travis-core/contents/.travis.yml?ref=12345678'
    end

    it 'returns the api url to the .travis.yml file on github with a gh endpoint given' do
      GH.set api_url: 'http://localhost/api/v3'
      request.config_url.should == 'http://localhost/api/v3/repos/travis-ci/travis-core/contents/.travis.yml?ref=12345678'
    end
  end

  describe 'api_request?' do
    it 'returns true if the event_type is api' do
      request.event_type = 'api'
      request.api_request?.should == true
    end

    it 'returns false if the event_type is not api' do
      request.event_type = 'push'
      request.api_request?.should == false
    end
  end

  describe 'pull_request?' do
    it 'returns true if the event_type is pull_request' do
      request.event_type = 'pull_request'
      request.pull_request?.should == true
    end

    it 'returns false if the event_type is not pull_request' do
      request.event_type = 'push'
      request.pull_request?.should == false
    end
  end

  describe 'pull_request_title' do
    let(:pull_request) { PullRequest.new(title: 'A pull request') }

    it 'returns the title of the pull request from payload' do
      request.event_type = 'pull_request'
      request.pull_request_title.should == 'A pull request'
    end

    it 'returns nil for non pull request' do
      request.event_type = 'push'
      request.pull_request_title.should be_nil
    end
  end

  describe 'pull_request_number' do
    let(:pull_request) { PullRequest.new(number: 1) }
    before { request.event_type = 'pull_request' }

    it 'returns the title of the pull request from payload' do
      request.event_type = 'pull_request'
      request.pull_request_number.should == 1
    end

    it 'returns nil for non pull request' do
      request.event_type = 'push'
      request.pull_request_number.should be_nil
    end
  end

  describe 'tag_name' do
    it 'returns a tag name if available' do
      commit.ref = 'refs/tags/foo'
      request.tag_name.should == 'foo'
    end

    it 'returns nil if a tag name is not available' do
      commit.ref = 'refs/heads/foo'
      request.tag_name.should be_nil
    end
  end

  describe 'branch_name' do
    it 'returns a branch name if available' do
      commit.branch = 'foo'
      request.branch_name.should == 'foo'
    end

    it 'returns nil if a branch name is not available' do
      commit.branch = nil
      request.branch_name.should be_nil
    end
  end

  describe '#head_repo' do
    it 'returns a branch name if available' do
      request.pull_request = PullRequest.new(head_repo_slug: 'foo/bar')
      request.head_repo.should == 'foo/bar'
    end
  end

  describe '#head_branch' do
    it 'returns a branch name if available' do
      request.pull_request = PullRequest.new(head_ref: 'foo')
      request.head_branch.should == 'foo'
    end
  end

  describe 'same_repo_pull_request?' do
    describe 'returns true if the base and head repos match' do
      let(:pull_request) { PullRequest.new(head_repo_slug: 'travis-ci/travis-core') }
      it { request.same_repo_pull_request?.should be_truthy }
    end

    describe 'returns false if the base and head repos do not match' do
      let(:pull_request) { PullRequest.new(head_repo_slug: 'BanzaiMan/travis-core') }
      it { request.same_repo_pull_request?.should be_falsey }
    end

    describe 'returns false if repo data is not available' do
      let(:pull_request) { PullRequest.new }
      it { request.same_repo_pull_request?.should be_falsey }
    end
  end
end

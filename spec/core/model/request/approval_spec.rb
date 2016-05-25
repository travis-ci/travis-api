require 'spec_helper'

describe Request::Approval do
  include Travis::Testing::Stubs

  let(:approval) { Request::Approval.new(request) }

  before do
    approval.stubs(:build_pull_requests?).returns(true)
    approval.stubs(:build_pushes?).returns(true)
    request.stubs(:creates_jobs?).returns(true)
  end

  describe 'config_accepted?' do
    it 'approves the build when .travis.yml is missing, but builds with .travis.yml are allowed' do
      request.config['.result'] = 'not_found'
      approval.config_accepted?.should be_true
    end

    it 'does not approve the build if .travis.yml is missing and builds without it are not allowed' do
      request.repository.stubs(:builds_only_with_travis_yml?).returns(true)
      request.config['.result'] = 'not_found'

      approval.config_accepted?.should be_false
      approval.message.should == '.travis.yml is missing and builds without .travis.yml are disabled'
    end

    it 'approves the build when .travis.yml is present' do
      request.config['.result'] = 'configured'
      approval.config_accepted?.should be_true
    end
  end

  describe 'branch_accepted?' do
    it 'does not accept a request that belongs to the github_pages branch' do
      request.commit.stubs(:branch).returns('gh_pages')
      approval.branch_accepted?.should be_false
    end

    it 'accepts a request that belongs to the gh-pages branch if it\'s specified in branches:only' do
      request.commit.stubs(:branch).returns('gh_pages')
      request.config['branches'] = { 'only' => ['gh-pages'] }
      approval.branch_accepted?.should be_true
    end

    it "doesn't fail when the branch configuration is an array" do
      request.config['branches'] = [{ 'only' => ['gh-pages'] }]
      approval.branch_accepted?.should be_true
    end
  end

  describe 'accepted?' do
    it 'accepts a request that has a commit, belongs to a public repository, is not skipped and does not belong to the github_pages branch and it is not a rails fork' do
      approval.should be_accepted
    end

    it 'does not accept a request that does not have a commit' do
      approval.stubs(:commit).returns(nil)
      approval.should_not be_accepted
    end

    it 'does not accept a request that belongs to a private repository' do
      request.repository.stubs(:private?).returns(true)
      approval.should_not be_accepted
    end

    it 'does not accept a request that belongs to an excluded repository' do
      request.repository.stubs(:slug).returns('svenfuchs/rails')
      approval.should_not be_accepted
    end

    it 'does not accept a request that is skipped (using the commit message)' do
      request.commit.stubs(:message).returns('update README [ci:skip]')
      approval.should_not be_accepted
    end

    it 'accepts a request that belongs to the github_pages branch and is explicitly set to build that branch (String)' do
      request.commit.stubs(:branch).returns('gh_pages')
      request.stubs(:config).returns('branches' => { 'only' => 'gh_pages' })
      approval.should be_accepted
    end

    it 'accepts a request that belongs to the github_pages branch and is explicitly set to build that branch (Array)' do
      request.commit.stubs(:branch).returns('gh_pages')
      request.stubs(:config).returns('branches' => { 'only' => ['gh_pages'] })
      approval.should be_accepted
    end

    it 'does not accept a request when it is disabled in settings' do
      approval.stubs(:enabled_in_settings?).returns(false)
      approval.should_not be_accepted
    end

    it 'does not accept a request when compare URL is too long' do
      request.commit.stubs(:compare_url).returns('a'*256)
      approval.should_not be_accepted
    end
  end

  describe 'approved?' do
    xit 'should be specified'
  end

  describe 'message' do
    it 'returns "pull requests disabled" if pull requests are disabled' do
      approval.stubs(:enabled_in_settings?).returns(false)
      request.stubs(:pull_request?).returns(true)
      approval.message.should == 'pull requests disabled'
    end

    it 'returns "pushes disabled" if pushes are disabled' do
      approval.stubs(:enabled_in_settings?).returns(false)
      request.stubs(:pull_request?).returns(false)
      approval.message.should == 'pushes disabled'
    end

    it 'returns "missing commit" if the commit is missing' do
      approval.stubs(:commit).returns(nil)
      approval.message.should == 'missing commit'
    end

    it 'returns "private repository" if the repository is private' do
      request.repository.stubs(:private?).returns(true)
      request.stubs(:config).returns({key: 'value'})
      approval.message.should == 'private repository'
    end

    it 'returns "excluded repository" if the repository is an excluded repository' do
      request.repository.stubs(:slug).returns('svenfuchs/rails')
      approval.message.should == 'excluded repository'
    end

    it 'returns "excluded repository" if the repository is an excluded repository and exclude rule is a string' do
      Travis.config.repository_filter.stubs(:exclude).returns(["\\/rails$"])
      request.repository.stubs(:slug).returns('svenfuchs/rails')
      approval.message.should == 'excluded repository'
    end

    it 'returns "github pages branch" if the branch is a github pages branch' do
      request.commit.stubs(:branch).returns('gh-pages')
      approval.message.should == 'github pages branch'
    end

    it 'returns "config is missing or contains YAML syntax error" if the config is not present' do
      request.stubs(:config).returns(nil)
      approval.message.should == 'config is missing or contains YAML syntax error'
    end

    it 'returns "branch not included or excluded" if the branch was not approved' do
      request.commit.stubs(:branch).returns('feature')
      request.stubs(:config).returns('branches' => { 'only' => 'master' })
      approval.message.should == 'branch not included or excluded'
    end

    it 'returns "compare URL too long; branch/tag names may be too long" if the compare URL is too long' do
      request.stubs(:config).returns({key: 'value'})
      request.commit.stubs(:compare_url).returns('a'*256)
      approval.message.should == 'compare URL too long; branch/tag names may be too long'
    end
  end

  describe 'skipped?' do
    it 'returns true when the commit message contains [ci skip]' do
      request.commit.stubs(:message).returns 'lets party like its 1999 [ci skip]'
      approval.send(:skipped?).should be_true
    end
  end

  describe 'github_pages?' do
    it 'returns true for a branch named gh-pages' do
      request.commit.stubs(:branch).returns 'gh-pages'
      approval.send(:github_pages?).should be_true
    end

    it 'returns true for a branch named gh_pages' do
      request.commit.stubs(:branch).returns 'gh_pages'
      approval.send(:github_pages?).should be_true
    end

    it 'returns true when a PR is for gh_pages' do
      request.commit.stubs(:ref).returns 'refs/pulls/1/merge'
      request.commit.stubs(:branch).returns 'gh_pages'
      approval.send(:github_pages?).should be_true
    end

    it 'returns false for a branch named master' do
      commit.stubs(:branch).returns 'master'
      approval.send(:github_pages?).should be_false
    end
  end

  describe 'included_repository?' do
    it 'returns true if the repository is an included repository' do
      request.repository.stubs(:slug).returns 'rails/rails'
      approval.send(:included_repository?).should be_true
    end

    it 'returns true if the repository is an included repository with rule as a string' do
      Travis.config.repository_filter.stubs(:include).returns(["rails\\/rails"])
      request.repository.stubs(:slug).returns 'rails/rails'
      approval.send(:included_repository?).should be_true
    end

    it 'returns false if the repository is not included' do
      request.repository.stubs(:slug).returns 'josh/completeness-fu'
      approval.send(:included_repository?).should be_false
    end

    it 'returns false if the repository is not included with rule as a string' do
      Travis.config.repository_filter.stubs(:include).returns(["rails\\/rails"])
      request.repository.stubs(:slug).returns 'josh/completeness-fu'
      approval.send(:included_repository?).should be_false
    end
  end

  describe 'excluded_repository?' do
    it 'returns true if the repository is an excluded repository' do
      request.repository.stubs(:slug).returns 'josh/rails'
      approval.send(:excluded_repository?).should be_true
    end

    it 'returns false if the repository is not excluded' do
      request.repository.stubs(:slug).returns 'josh/completeness-fu'
      approval.send(:excluded_repository?).should be_false
    end

    it 'returns true if the repository is an excluded repository with rule as a string' do
      Travis.config.repository_filter.stubs(:exclude).returns(["\\/rails$"])
      request.repository.stubs(:slug).returns 'josh/rails'
      approval.send(:excluded_repository?).should be_true
    end

    it 'returns false if the repository is not excluded with rule as a string' do
      Travis.config.repository_filter.stubs(:exclude).returns(["\\/rails$"])
      request.repository.stubs(:slug).returns 'josh/completeness-fu'
      approval.send(:excluded_repository?).should be_false
    end
  end

  describe 'enabled_in_settings?' do
    it 'returns true if a request is an api request' do
      request.stubs(:api_request?).returns(true)
      approval.enabled_in_settings?.should be_true
    end

    it 'returns true if pull requests are enabled and a request is a pull request' do
      request.stubs(:pull_request?).returns(true)
      approval.stubs(:build_pull_requests?).returns(true)
      approval.enabled_in_settings?.should be_true
    end

    it 'returns true if pushes are enabled and a request is a push' do
      request.stubs(:pull_request?).returns(false)
      approval.stubs(:build_pushes?).returns(true)
      approval.enabled_in_settings?.should be_true
    end

    it 'returns false if pull requests are disabled and a request is a pull request' do
      request.stubs(:pull_request?).returns(true)
      approval.stubs(:build_pull_requests?).returns(false)
      approval.enabled_in_settings?.should be_false
    end

    it 'returns false if pushes are disabled and a request is a push' do
      request.stubs(:pull_request?).returns(false)
      approval.stubs(:build_pushes?).returns(false)
      approval.enabled_in_settings?.should be_false
    end
  end
end

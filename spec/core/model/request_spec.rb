require 'spec_helper'

describe Request do
  include Support::ActiveRecord

  let(:repo)    { Repository.new(owner_name: 'travis-ci', name: 'travis-ci') }
  let(:commit)  { Commit.new(commit: '12345678') }
  let(:request) { Request.new(repository: repo, commit: commit) }

  describe 'config_url' do
    before :each do
      GH.options.delete(:api_url)
      GH.current = nil
    end

    after :each do
      GH.set api_url: nil
    end

    it 'returns the api url to the .travis.yml file on github' do
      request.config_url.should == 'https://api.github.com/repos/travis-ci/travis-ci/contents/.travis.yml?ref=12345678'
    end

    it 'returns the api url to the .travis.yml file on github with a gh endpoint given' do
      GH.set api_url: 'http://localhost/api/v3'
      request.config_url.should == 'http://localhost/api/v3/repos/travis-ci/travis-ci/contents/.travis.yml?ref=12345678'
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
    it 'returns the title of the pull request from payload' do
      request.event_type = 'pull_request'
      request.payload = { 'pull_request' => { 'title' => 'A pull request' } }

      request.pull_request_title.should == 'A pull request'
    end

    it 'returns nil for non pull request' do
      request.event_type = 'build'
      request.payload = { 'pull_request' => { 'title' => 'A pull request' } }

      request.pull_request_title.should be_nil
    end
  end

  describe 'tag_name' do
    it 'returns a tag name if available' do
      request.payload = { 'ref' => 'refs/tags/foo' }

      request.tag_name.should == 'foo'
    end

    it 'returns nil if a tag name is not available' do
      request.payload = { 'ref' => 'refs/heads/foo' }

      request.tag_name.should be_nil
    end
  end

  describe 'branch_name' do
    it 'returns a branch name if available' do
      request.payload = { 'ref' => 'refs/heads/foo' }

      request.branch_name.should == 'foo'
    end

    it 'returns nil if a branch name is not available' do
      request.payload = { 'ref' => 'refs/tags/foo' }

      request.branch_name.should be_nil
    end
  end

  describe '#head_repo' do
    it 'returns a branch name if available' do
      request.payload = { 'pull_request' => { 'head' => { 'repo' => { 'full_name' => 'foo/bar' } } } }

      request.head_repo.should == 'foo/bar'
    end

    it 'returns nil if this is not a pull request' do
      request.payload = { }

      request.head_repo.should be_nil
    end
  end

  describe '#head_branch' do
    it 'returns a branch name if available' do
      request.payload = { 'pull_request' => { 'head' => { 'ref' => 'foo' } } }

      request.head_branch.should == 'foo'
    end

    it 'returns nil if this is not a pull request' do
      request.payload = { }

      request.head_branch.should be_nil
    end
  end

  describe 'same_repo_pull_request?' do
    it 'returns true if the base and head repos match' do
      request.payload = {
        'pull_request' => {
          'base' => { 'repo' => { 'full_name' => 'travis-ci/travis-core' } },
          'head' => { 'repo' => { 'full_name' => 'travis-ci/travis-core' } },
        }
      }

      request.same_repo_pull_request?.should be_true
    end

    it 'returns false if the base and head repos do not match' do
      request.payload = {
        'pull_request' => {
          'base' => { 'repo' => { 'full_name' => 'travis-ci/travis-core' } },
          'head' => { 'repo' => { 'full_name' => 'BanzaiMan/travis-core' } },
        }
      }

      request.same_repo_pull_request?.should be_false
    end

    it 'returns false if repo data is not available' do
      request.payload = {}

      request.same_repo_pull_request?.should be_false
    end
  end
end

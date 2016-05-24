require 'spec_helper'

describe Repository do
  include Support::ActiveRecord

  describe '#last_completed_build' do
    let(:repo)   {  Factory(:repository, name: 'foobarbaz', builds: [build1, build2]) }
    let(:build1) { Factory(:build, finished_at: 1.hour.ago, state: :passed) }
    let(:build2) { Factory(:build, finished_at: Time.now, state: :failed) }

    before do
      build1.update_attributes(branch: 'master')
      build2.update_attributes(branch: 'development')
    end

    it 'returns last completed build' do
      repo.last_completed_build.should == build2
    end

    it 'returns last completed build for a branch' do
      repo.last_completed_build('master').should == build1
    end
  end

  describe '#regenerate_key!' do
    it 'regenerates key' do
      repo = Factory(:repository)

      expect { repo.regenerate_key! }.to change { repo.key.private_key }
    end
  end

  describe 'associations' do
    describe 'owner' do
      let(:user) { Factory(:user) }
      let(:org)  { Factory(:org)  }

      it 'can be a user' do
        repo = Factory(:repository, owner: user)
        repo.reload.owner.should == user
      end

      it 'can be an organization' do
        repo = Factory(:repository, owner: org)
        repo.reload.owner.should == org
      end
    end
  end

  describe 'class methods' do
    describe 'find_by' do
      let(:minimal) { Factory(:repository) }

      it "should find a repository by it's github_id" do
        Repository.find_by(github_id: minimal.github_id).should == minimal
      end

      it "should find a repository by it's id" do
        Repository.find_by(id: minimal.id).id.should == minimal.id
      end

      it "should find a repository by it's name and owner_name" do
        repo = Repository.find_by(name: minimal.name, owner_name: minimal.owner_name)
        repo.owner_name.should == minimal.owner_name
        repo.name.should == minimal.name
      end

      it "returns nil when a repository couldn't be found using params" do
        Repository.find_by(name: 'emptiness').should be_nil
      end
    end

    describe 'timeline' do
      before do
        Factory(:repository, name: 'unbuilt 1',   active: true, last_build_started_at: nil, last_build_finished_at: nil)
        Factory(:repository, name: 'unbuilt 2',   active: true, last_build_started_at: nil, last_build_finished_at: nil)
        Factory(:repository, name: 'finished 1',  active: true, last_build_started_at: '2011-11-12 12:00:00', last_build_finished_at: '2011-11-12 12:00:05')
        Factory(:repository, name: 'finished 2',  active: true, last_build_started_at: '2011-11-12 12:00:01', last_build_finished_at: '2011-11-11 12:00:06')
        Factory(:repository, name: 'started 1',   active: true, last_build_started_at: '2011-11-11 12:00:00', last_build_finished_at: nil)
        Factory(:repository, name: 'started 2',   active: true, last_build_started_at: '2011-11-11 12:00:01', last_build_finished_at: nil)
        Factory(:repository, name: 'invalidated', active: true, last_build_started_at: '2011-11-11 12:00:01', last_build_finished_at: nil, invalidated_at: '2012-11-11 12:00:06')
      end

      it 'sorts repositories with running builds to the top, most recent builds next, un-built repos last' do
        repositories = Repository.timeline
        repositories.map(&:name).should == ['started 2', 'started 1', 'finished 2', 'finished 1', 'unbuilt 2', 'unbuilt 1']
      end

      it 'does not include invalidated repos' do
        repositories = Repository.timeline
        repositories.map(&:name).should_not include('invalidated')
      end
    end

    describe 'with_builds' do
      it 'gets only projects with existing builds' do
        one   = Factory(:repository, name: 'one',   last_build_started_at: '2011-11-11', last_build_id: nil)
        two   = Factory(:repository, name: 'two',   last_build_started_at: '2011-11-12', last_build_id: 101)
        three = Factory(:repository, name: 'three', last_build_started_at: nil, last_build_id: 100)

        repositories = Repository.with_builds.all
        repositories.map(&:id).sort.should == [two, three].map(&:id).sort
      end
    end

    describe 'active' do
      let(:active)      { Factory(:repository, active: true) }
      let(:inactive)    { Factory(:repository, active: false) }
      let(:invalidated) { Factory(:repository, invalidated_at: Time.now) }

      it 'contains active repositories' do
        Repository.active.should include(active)
      end

      it 'does not include inactive repositories' do
        Repository.active.should_not include(inactive)
      end

      it 'does not include invalidated repositories' do
        Repository.active.should_not include(invalidated)
      end
    end

    describe 'search' do
      before(:each) do
        Factory(:repository, name: 'repo 1', last_build_started_at: '2011-11-11')
        Factory(:repository, name: 'repo 2', last_build_started_at: '2011-11-12')
        Factory(:repository, name: 'invalidated', invalidated_at: Time.now)
      end

      it 'performs searches case-insensitive' do
        Repository.search('rEpO').to_a.count.should == 2
      end

      it 'performs searches with / entered' do
        Repository.search('fuchs/').to_a.count.should == 2
      end

      it 'performs searches with \ entered' do
        Repository.search('fuchs\\').to_a.count.should == 2
      end

      it 'does not find invalidated repos' do
        Repository.search('fuchs').map(&:name).should_not include('invalidated')
      end
    end

    describe 'by_member' do
      let(:user)        { Factory(:user) }
      let(:org)         { Factory(:org) }
      let(:user_repo)   { Factory(:repository, owner: user)}
      let(:org_repo)    { Factory(:repository, owner: org, name: 'globalize')}
      let(:invalidated) { Factory(:repository, owner: org, name: 'invalidated', invalidated_at: Time.now)}
      before do
        Permission.create!(user: user, repository: user_repo, pull: true, push: true)
        Permission.create!(user: user, repository: org_repo, pull: true)
        Permission.create!(user: user, repository: invalidated, pull: true)
      end

      it 'returns all repositories a user has rights to' do
        Repository.by_member('svenfuchs').should have(2).items
      end

      it 'does not find invalidated repos' do
        Repository.by_member('svenfuchs').map(&:name).should_not include('invalidated')
      end
    end

    describe 'counts_by_owner_names' do
      let!(:repositories) do
        Factory(:repository, owner_name: 'svenfuchs', name: 'minimal')
        Factory(:repository, owner_name: 'travis-ci', name: 'travis-ci')
        Factory(:repository, owner_name: 'travis-ci', name: 'invalidated', invalidated_at: Time.now)
      end

      it 'returns repository counts per owner_name for the given owner_names' do
        counts = Repository.counts_by_owner_names(%w(svenfuchs travis-ci))
        counts.should == { 'svenfuchs' => 1, 'travis-ci' => 1 }
      end
    end
  end

  describe 'api_url' do
    let(:repo) { Repository.new(owner_name: 'travis-ci', name: 'travis-ci') }

    before :each do
      Travis.config.github.api_url = 'https://api.github.com'
    end

    it 'returns the api url for the repository' do
      repo.api_url.should == 'https://api.github.com/repos/travis-ci/travis-ci'
    end
  end

  describe 'source_url' do
    describe 'default source endpoint' do
      let(:repo) { Repository.new(owner_name: 'travis-ci', name: 'travis-ci') }

      before :each do
        Travis.config.github.source_host = nil
      end

      it 'returns the public git source url for a public repository' do
        repo.private = false
        repo.source_url.should == 'git://github.com/travis-ci/travis-ci.git'
      end

      it 'returns the private git source url for a private repository' do
        repo.private = true
        repo.source_url.should == 'git@github.com:travis-ci/travis-ci.git'
      end
    end

    describe 'custom source endpoint' do
      let(:repo) { Repository.new(owner_name: 'travis-ci', name: 'travis-ci') }

      before :each do
        Travis.config.github.source_host = 'localhost'
      end

      it 'returns the private git source url for a public repository' do
        repo.private = false
        repo.source_url.should == 'git@localhost:travis-ci/travis-ci.git'
      end

      it 'returns the private git source url for a private repository' do
        repo.private = true
        repo.source_url.should == 'git@localhost:travis-ci/travis-ci.git'
      end
    end
  end

  describe 'source_host' do
    before :each do
      Travis.config.github.stubs(:source_host).returns('localhost')
    end

    it 'returns the source_host name from Travis.config' do
      Repository.new.source_host.should == 'localhost'
    end
  end

  describe "#last_build" do
    let(:repo) { Factory(:repository) }
    let(:attributes) { { repository: repo, state: 'finished' } }
    let(:api_req)    { Factory(:request, {event_type: 'api'}) }

    before :each do
      Factory(:build, attributes)
      Factory(:build, attributes)
    end

    context 'when last build is a push build' do
      before :each do
        @build = Factory(:build, attributes)
      end

      it 'returns the most recent build' do
        repo.last_build('master').id.should == @build.id
      end
    end

    context 'when last build is an API build' do
      before :each do
        @build = Factory(:build, attributes.merge({request: api_req}))
      end

      it 'returns the most recent build' do
        repo.last_build('master').id.should == @build.id
      end
    end
  end

  describe '#last_build_on' do
    let(:repo)       { Factory(:repository) }
    let(:attributes) { { repository: repo, state: 'finished' } }
    let(:api_req)    { Factory(:request, {event_type: 'api'}) }

    before :each do
      Factory(:build, attributes)
    end

    context 'when last build is a push build' do
      before :each do
        @build = Factory(:build, attributes)
      end

      it 'returns the most recent build' do
        repo.last_build_on('master').id.should == @build.id
      end
    end

    context 'when last build is an API build' do
      before :each do
        @build = Factory(:build, attributes.merge({request: api_req}))
      end

      it 'returns the most recent build' do
        repo.last_build_on('master').id.should == @build.id
      end
    end
  end

  describe "keys" do
    let(:repo) { Factory(:repository) }

    it "should return the public key" do
      repo.public_key.should == repo.key.public_key
    end

    it "should create a new key when the repository is created" do
      repo = Repository.create!(owner_name: 'travis-ci', name: 'travis-ci')
      repo.key.should_not be_nil
    end
  end

  describe 'branches' do
    let(:repo) { Factory(:repository) }

    it 'returns branches for the given repository' do
      %w(master production).each do |branch|
        2.times { Factory(:build, repository: repo, commit: Factory(:commit, branch: branch)) }
      end
      repo.branches.sort.should == %w(master production)
    end

    it 'is empty for empty repository' do
      repo.branches.should eql []
    end
  end

  describe 'settings' do
    let(:repo) { Factory.build(:repository) }

    it 'adds repository_id to collection records' do
      repo.save

      env_var = repo.settings.env_vars.create(name: 'FOO')
      env_var.repository_id.should == repo.id

      repo.settings.save

      repo.reload

      repo.settings.env_vars.first.repository_id.should == repo.id
    end

    it "is reset on reload" do
      repo.save

      repo.settings = {}
      repo.update_column(:settings, { 'build_pushes' => false }.to_json)
      repo.reload
      repo.settings.build_pushes?.should be_false
      repo.update_column(:settings, { 'build_pushes' => true }.to_json)
      repo.reload
      repo.settings.build_pushes?.should be_true
    end

    it "allows to set nil for settings" do
      repo.settings = nil
      repo.settings.to_hash.should == Repository::Settings.new.to_hash
    end

    it "allows to set settings as JSON string" do
      repo.settings = '{"maximum_number_of_builds": 44}'
      repo.settings.to_hash.should == Repository::Settings.new(maximum_number_of_builds: 44).to_hash
    end

    it "allows to set settings as a Hash" do
      repo.settings = { maximum_number_of_builds: 44}
      repo.settings.to_hash.should == Repository::Settings.new(maximum_number_of_builds: 44).to_hash
    end

    it 'updates settings in the DB' do
      repo.settings = {'build_pushes' => false}
      repo.save

      repo.reload.settings.build_pushes?.should == false

      repo.settings.merge('build_pushes' => true)
      repo.settings.save

      repo.reload.settings.build_pushes?.should == true
    end
  end

  describe 'last_finished_builds_by_branches' do
    let(:repo) { Factory(:repository) }

    it 'properly orders branches by last build' do
      Build.delete_all
      one = Factory(:build, repository: repo, finished_at: 2.hours.ago, state: 'finished', commit: Factory(:commit, branch: '1one'))
      two = Factory(:build, repository: repo, finished_at: 1.hours.ago, state: 'finished', commit: Factory(:commit, branch: '2two'))

      builds = repo.last_finished_builds_by_branches(1)
      builds.should == [two]
    end

    it 'retrieves last builds on all branches' do
      Build.delete_all
      old = Factory(:build, repository: repo, finished_at: 1.hour.ago,      state: 'finished', commit: Factory(:commit, branch: 'one'))
      one = Factory(:build, repository: repo, finished_at: 1.hour.from_now, state: 'finished', commit: Factory(:commit, branch: 'one'))
      two = Factory(:build, repository: repo, finished_at: 1.hour.from_now, state: 'finished', commit: Factory(:commit, branch: 'two'))
      three = Factory(:build, repository: repo, finished_at: 1.hour.from_now, state: 'finished', commit: Factory(:commit, branch: 'three'))
      three.update_attribute(:event_type, 'pull_request')

      builds = repo.last_finished_builds_by_branches
      builds.size.should == 2
      builds.should include(one)
      builds.should include(two)
      builds.should_not include(old)
    end
  end

  describe '#users_with_permission' do
    it 'returns users with the given permission linked to that repository' do
      repo = Factory(:repository)
      other_repo = Factory(:repository)

      user_with_permission = Factory(:user)
      user_with_permission.permissions.create!(repository: repo, admin: true)

      user_wrong_repo = Factory(:user)
      user_wrong_repo.permissions.create!(repository: other_repo, admin: true)

      user_wrong_permission = Factory(:user)
      user_wrong_permission.permissions.create!(repository: repo, push: true)

      repo.users_with_permission(:admin).should include(user_with_permission)
      repo.users_with_permission(:admin).should_not include(user_wrong_repo)
      repo.users_with_permission(:admin).should_not include(user_wrong_permission)
    end
  end
end

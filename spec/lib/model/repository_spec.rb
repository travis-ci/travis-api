describe Repository do
  before { DatabaseCleaner.clean_with :truncation }

  describe '#last_completed_build' do
    let(:repo)   { FactoryGirl.create(:repository, name: 'foobarbaz') }
    let(:build1) { FactoryGirl.create(:build, repository: repo, finished_at: 1.hour.ago, state: :passed) }
    let(:build2) { FactoryGirl.create(:build, repository: repo, finished_at: Time.now, state: :failed) }

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
    let(:repo) { FactoryGirl.create(:repository) }
    before { repo.regenerate_key! }
    it 'regenerates key' do
      expect { repo.regenerate_key! }.to change { repo.key.private_key }
    end
  end

  describe 'associations' do
    describe 'owner' do
      let(:user) { FactoryGirl.create(:user) }
      let(:org)  { FactoryGirl.create(:org)  }

      it 'can be a user' do
        repo = FactoryGirl.create(:repository, owner: user)
        repo.reload.owner.should == user
      end

      it 'can be an organization' do
        repo = FactoryGirl.create(:repository, owner: org)
        repo.reload.owner.should == org
      end
    end
  end

  describe 'class methods' do
    describe 'by_params' do
      let(:minimal) { FactoryGirl.create(:repository) }

      it "should find a repository by it's github_id" do
        Repository.by_params(github_id: minimal.github_id).to_a.first.should == minimal
      end

      it "should find a repository by it's id" do
        Repository.by_params(id: minimal.id).to_a.first.id.should == minimal.id
      end

      it "should find a repository by it's name and owner_name" do
        repo = Repository.by_params(name: minimal.name, owner_name: minimal.owner_name).to_a.first
        repo.owner_name.should == minimal.owner_name
        repo.name.should == minimal.name
      end

      it "returns nil when a repository couldn't be found using params" do
        Repository.by_params(name: 'emptiness').to_a.should == []
      end
    end

    describe 'timeline' do
      before do
        FactoryGirl.create(:repository, name: 'unbuilt 1',   active: true, last_build_started_at: nil, last_build_finished_at: nil)
        FactoryGirl.create(:repository, name: 'unbuilt 2',   active: true, last_build_started_at: nil, last_build_finished_at: nil)
        FactoryGirl.create(:repository, name: 'finished 1',  active: true, last_build_started_at: '2011-11-12 12:00:00', last_build_finished_at: '2011-11-12 12:00:05')
        FactoryGirl.create(:repository, name: 'finished 2',  active: true, last_build_started_at: '2011-11-12 12:00:01', last_build_finished_at: '2011-11-11 12:00:06')
        FactoryGirl.create(:repository, name: 'started 1',   active: true, last_build_started_at: '2011-11-11 12:00:00', last_build_finished_at: nil)
        FactoryGirl.create(:repository, name: 'started 2',   active: true, last_build_started_at: '2011-11-11 12:00:01', last_build_finished_at: nil)
        FactoryGirl.create(:repository, name: 'invalidated', active: true, last_build_started_at: '2011-11-11 12:00:01', last_build_finished_at: nil, invalidated_at: '2012-11-11 12:00:06')
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
        one   = FactoryGirl.create(:repository, name: 'one',   last_build_started_at: '2011-11-11', last_build_id: nil)
        two   = FactoryGirl.create(:repository, name: 'two',   last_build_started_at: '2011-11-12')
        three = FactoryGirl.create(:repository, name: 'three', last_build_started_at: nil)
        two.last_build_id = FactoryGirl.create(:build, repository: two).id
        two.save
        three.last_build_id = FactoryGirl.create(:build, repository: three).id
        three.save

        repositories = Repository.with_builds.all
        repositories.map(&:id).sort.should == [two, three].map(&:id).sort
      end
    end

    describe 'active' do
      let(:active)      { FactoryGirl.create(:repository, active: true) }
      let(:inactive)    { FactoryGirl.create(:repository, active: false) }
      let(:invalidated) { FactoryGirl.create(:repository, invalidated_at: Time.now) }

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
        FactoryGirl.create(:repository, name: 'repo 1', last_build_started_at: '2011-11-11')
        FactoryGirl.create(:repository, name: 'repo 2', last_build_started_at: '2011-11-12')
        FactoryGirl.create(:repository, name: 'invalidated', invalidated_at: Time.now)
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
      let(:user)        { FactoryGirl.create(:user) }
      let(:org)         { FactoryGirl.create(:org) }
      let(:user_repo)   { FactoryGirl.create(:repository, owner: user)}
      let(:org_repo)    { FactoryGirl.create(:repository, owner: org, name: 'globalize')}
      let(:invalidated) { FactoryGirl.create(:repository, owner: org, name: 'invalidated', invalidated_at: Time.now)}
      before do
        Permission.create!(user: user, repository: user_repo, pull: true, push: true)
        Permission.create!(user: user, repository: org_repo, pull: true)
        Permission.create!(user: user, repository: invalidated, pull: true)
      end

      it 'returns all repositories a user has rights to' do
        expect(Repository.by_member('svenfuchs').size).to eq(2)
      end

      it 'does not find invalidated repos' do
        Repository.by_member('svenfuchs').map(&:name).should_not include('invalidated')
      end
    end

    describe 'counts_by_owner_ids' do
      let!(:repositories) do
        FactoryGirl.create(:repository, owner: FactoryGirl.create(:org), owner_name: 'svenfuchs', name: 'minimal')
        FactoryGirl.create(:repository, owner: FactoryGirl.create(:org), owner_name: 'travis-ci', name: 'travis-ci')
        FactoryGirl.create(:repository, owner: FactoryGirl.create(:org), owner_name: 'travis-ci', name: 'invalidated', invalidated_at: Time.now)
      end

      it 'returns repository counts per owner_id for the given owner_ids' do
        counts = Repository.counts_by_owner_ids([1, 2], 'Organization')
        counts.should == { 1 => 1, 2 => 1 }
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
      Travis.config.github.source_host = 'localhost'
    end

    it 'returns the source_host name from Travis.config' do
      Repository.new.source_host.should == 'localhost'
    end
  end

  describe "#last_build" do
    let(:repo) { FactoryGirl.create(:repository) }
    let(:attributes) { { repository: repo, state: 'finished' } }
    let(:api_req)    { FactoryGirl.create(:request, {event_type: 'api'}) }

    before :each do
      FactoryGirl.create(:build, attributes)
      FactoryGirl.create(:build, attributes)
    end

    context 'when last build is a push build' do
      before :each do
        @build = FactoryGirl.create(:build, attributes)
      end

      it 'returns the most recent build' do
        repo.last_build('master').id.should == @build.id
      end
    end

    context 'when last build is an API build' do
      before :each do
        @build = FactoryGirl.create(:build, attributes.merge({request: api_req}))
      end

      it 'returns the most recent build' do
        repo.last_build('master').id.should == @build.id
      end
    end
  end

  describe '#last_build_on' do
    let(:repo)       { FactoryGirl.create(:repository) }
    let(:attributes) { { repository: repo, state: 'finished' } }
    let(:api_req)    { FactoryGirl.create(:request, {event_type: 'api'}) }

    before :each do
      FactoryGirl.create(:build, attributes)
    end

    context 'when last build is a push build' do
      before :each do
        @build = FactoryGirl.create(:build, attributes)
      end

      it 'returns the most recent build' do
        repo.last_build_on('master').id.should == @build.id
      end
    end

    context 'when last build is an API build' do
      before :each do
        @build = FactoryGirl.create(:build, attributes.merge({request: api_req}))
      end

      it 'returns the most recent build' do
        repo.last_build_on('master').id.should == @build.id
      end
    end
  end

  describe "keys" do
    let(:repo) { FactoryGirl.create(:repository) }
    before { repo.regenerate_key! }

    it "should return the public key" do
      repo.public_key.should == repo.key.public_key
    end
  end

  describe 'branches' do
    let(:repo) { FactoryGirl.create(:repository) }

    it 'returns branches for the given repository' do
      %w(master production).each do |branch|
        2.times { FactoryGirl.create(:build, repository: repo, commit: FactoryGirl.create(:commit, branch: branch)) }
      end
      repo.branches.sort.should == %w(master production)
    end

    it 'is empty for empty repository' do
      repo.last_build_id = nil
      repo.save
      Build.delete_all
      repo.branches.should eql []
    end
  end

  describe 'settings' do
    let(:repo) { FactoryGirl.create.build(:repository) }

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
      repo.settings.build_pushes?.should be false
      repo.update_column(:settings, { 'build_pushes' => true }.to_json)
      repo.reload
      repo.settings.build_pushes?.should be true
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
    let(:repo) { FactoryGirl.create(:repository) }

    it 'properly orders branches by last build' do
      repo # load the repo
      Build.delete_all
      one = FactoryGirl.create(:build, repository: repo, finished_at: 2.hours.ago, state: 'finished', commit: FactoryGirl.create(:commit, branch: '1one'))
      two = FactoryGirl.create(:build, repository: repo, finished_at: 1.hours.ago, state: 'finished', commit: FactoryGirl.create(:commit, branch: '2two'))

      builds = repo.last_finished_builds_by_branches(1)
      builds.should == [two]
    end

    it 'retrieves last builds on all branches' do
      repo # load the repo
      Build.delete_all
      old = FactoryGirl.create(:build, repository: repo, number: 1, finished_at: 1.hour.ago,      state: 'finished', commit: FactoryGirl.create(:commit, branch: 'one'))
      one = FactoryGirl.create(:build, repository: repo, number: 2, finished_at: 1.hour.from_now, state: 'finished', commit: FactoryGirl.create(:commit, branch: 'one'))
      two = FactoryGirl.create(:build, repository: repo, number: 3, finished_at: 1.hour.from_now, state: 'finished', commit: FactoryGirl.create(:commit, branch: 'two'))
      three = FactoryGirl.create(:build, repository: repo, number: 4, finished_at: 1.hour.from_now, state: 'finished', commit: FactoryGirl.create(:commit, branch: 'three'))
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
      repo = FactoryGirl.create(:repository)
      other_repo = FactoryGirl.create(:repository)

      user_with_permission = FactoryGirl.create(:user)
      user_with_permission.permissions.create!(repository: repo, admin: true)

      user_wrong_repo = FactoryGirl.create(:user)
      user_wrong_repo.permissions.create!(repository: other_repo, admin: true)

      user_wrong_permission = FactoryGirl.create(:user)
      user_wrong_permission.permissions.create!(repository: repo, push: true)

      repo.users_with_permission(:admin).should include(user_with_permission)
      repo.users_with_permission(:admin).should_not include(user_wrong_repo)
      repo.users_with_permission(:admin).should_not include(user_wrong_permission)
    end
  end
end

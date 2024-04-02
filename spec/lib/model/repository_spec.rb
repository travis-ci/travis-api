describe Repository do
  before { DatabaseCleaner.clean_with :truncation }

  describe '#last_completed_build' do
    let(:repo)   { FactoryBot.create(:repository, name: 'foobarbaz') }
    let(:build1) { FactoryBot.create(:build, repository: repo, finished_at: 1.hour.ago, state: :passed) }
    let(:build2) { FactoryBot.create(:build, repository: repo, finished_at: Time.now, state: :failed) }

    before do
      build1.update(branch: 'master')
      build2.update(branch: 'development')
    end

    it 'returns last completed build' do
      expect(repo.last_completed_build).to eq(build2)
    end

    it 'returns last completed build for a branch' do
      expect(repo.last_completed_build('master')).to eq(build1)
    end
  end

  describe '#regenerate_key!' do
    let(:repo) { FactoryBot.create(:repository) }
    before { repo.regenerate_key! }
    it 'regenerates key' do
      expect { repo.regenerate_key! }.to change { repo.key.private_key }
    end
  end

  describe 'associations' do
    describe 'owner' do
      let(:user) { FactoryBot.create(:user) }
      let(:org)  { FactoryBot.create(:org)  }

      it 'can be a user' do
        repo = FactoryBot.create(:repository, owner: user, owner_type: 'User')
        expect(repo.reload.owner).to eq(user)
      end

      it 'can be an organization' do
        repo = FactoryBot.create(:repository, owner: org, owner_type: 'Organization')
        expect(repo.reload.owner).to eq(org)
      end
    end
  end

  describe 'class methods' do
    describe 'by_params' do
      let(:minimal) { FactoryBot.create(:repository) }

      it "should find a repository by it's github_id" do
        expect(Repository.by_params(github_id: minimal.github_id).to_a.first).to eq(minimal)
      end

      it "should find a repository by it's id" do
        expect(Repository.by_params(id: minimal.id).to_a.first.id).to eq(minimal.id)
      end

      it "should find a repository by it's name and owner_name" do
        repo = Repository.by_params(name: minimal.name, owner_name: minimal.owner_name).to_a.first
        expect(repo.owner_name).to eq(minimal.owner_name)
        expect(repo.name).to eq(minimal.name)
      end

      it "returns nil when a repository couldn't be found using params" do
        expect(Repository.by_params(name: 'emptiness').to_a).to eq([])
      end
    end

    describe 'timeline' do
      before do
        FactoryBot.create(:repository, name: 'unbuilt 1',   active: true, last_build_started_at: nil, last_build_finished_at: nil)
        FactoryBot.create(:repository, name: 'unbuilt 2',   active: true, last_build_started_at: nil, last_build_finished_at: nil)
        FactoryBot.create(:repository, name: 'finished 1',  active: true, last_build_started_at: '2011-11-12 12:00:00', last_build_finished_at: '2011-11-12 12:00:05')
        FactoryBot.create(:repository, name: 'finished 2',  active: true, last_build_started_at: '2011-11-12 12:00:01', last_build_finished_at: '2011-11-11 12:00:06')
        FactoryBot.create(:repository, name: 'started 1',   active: true, last_build_started_at: '2011-11-11 12:00:00', last_build_finished_at: nil)
        FactoryBot.create(:repository, name: 'started 2',   active: true, last_build_started_at: '2011-11-11 12:00:01', last_build_finished_at: nil)
        FactoryBot.create(:repository, name: 'invalidated', active: true, last_build_started_at: '2011-11-11 12:00:01', last_build_finished_at: nil, invalidated_at: '2012-11-11 12:00:06')
      end

      it 'sorts repositories with running builds to the top, most recent builds next, un-built repos last' do
        repositories = Repository.timeline
        expect(repositories.map(&:name)).to eq(['started 2', 'started 1', 'finished 2', 'finished 1', 'unbuilt 2', 'unbuilt 1'])
      end

      it 'does not include invalidated repos' do
        repositories = Repository.timeline
        expect(repositories.map(&:name)).not_to include('invalidated')
      end
    end

    describe 'with_builds' do
      it 'gets only projects with existing builds' do
        one   = FactoryBot.create(:repository, name: 'one',   last_build_started_at: '2011-11-11', last_build_id: nil)
        two   = FactoryBot.create(:repository, name: 'two',   last_build_started_at: '2011-11-12')
        three = FactoryBot.create(:repository, name: 'three', last_build_started_at: nil)
        two.last_build_id = FactoryBot.create(:build, repository: two).id
        two.save
        three.last_build_id = FactoryBot.create(:build, repository: three).id
        three.save

        repositories = Repository.with_builds.all
        expect(repositories.map(&:id).sort).to eq([two, three].map(&:id).sort)
      end
    end

    describe 'active' do
      let(:active)      { FactoryBot.create(:repository, active: true) }
      let(:inactive)    { FactoryBot.create(:repository, active: false) }
      let(:invalidated) { FactoryBot.create(:repository, invalidated_at: Time.now) }

      it 'contains active repositories' do
        expect(Repository.active).to include(active)
      end

      it 'does not include inactive repositories' do
        expect(Repository.active).not_to include(inactive)
      end

      it 'does not include invalidated repositories' do
        expect(Repository.active).not_to include(invalidated)
      end
    end

    describe 'search' do
      before(:each) do
        FactoryBot.create(:repository, name: 'repo 1', last_build_started_at: '2011-11-11')
        FactoryBot.create(:repository, name: 'repo 2', last_build_started_at: '2011-11-12')
        FactoryBot.create(:repository, name: 'invalidated', invalidated_at: Time.now)
      end

      it 'performs searches case-insensitive' do
        expect(Repository.search('rEpO').to_a.count).to eq(2)
      end

      it 'performs searches with / entered' do
        expect(Repository.search('fuchs/').to_a.count).to eq(2)
      end

      it 'performs searches with \ entered' do
        expect(Repository.search('fuchs\\').to_a.count).to eq(2)
      end

      it 'does not find invalidated repos' do
        expect(Repository.search('fuchs').map(&:name)).not_to include('invalidated')
      end
    end

    describe 'by_member' do
      let(:user)        { FactoryBot.create(:user) }
      let(:org)         { FactoryBot.create(:org) }
      let(:user_repo)   { FactoryBot.create(:repository, owner: user)}
      let(:org_repo)    { FactoryBot.create(:repository, owner: org, name: 'globalize')}
      let(:invalidated) { FactoryBot.create(:repository, owner: org, name: 'invalidated', invalidated_at: Time.now)}
      before do
        Permission.create!(user: user, repository: user_repo, pull: true, push: true)
        Permission.create!(user: user, repository: org_repo, pull: true)
        Permission.create!(user: user, repository: invalidated, pull: true)
      end

      it 'returns all repositories a user has rights to' do
        expect(Repository.by_member('svenfuchs').size).to eq(2)
      end

      it 'does not find invalidated repos' do
        expect(Repository.by_member('svenfuchs').map(&:name)).not_to include('invalidated')
      end
    end

    describe 'counts_by_owner_ids' do
      let!(:repositories) do
        FactoryBot.create(:repository, owner: FactoryBot.create(:org), owner_name: 'svenfuchs', name: 'minimal', owner_type: 'Organization')
        FactoryBot.create(:repository, owner: FactoryBot.create(:org), owner_name: 'travis-ci', name: 'travis-ci', owner_type: 'Organization')
        FactoryBot.create(:repository, owner: FactoryBot.create(:org), owner_name: 'travis-ci', name: 'invalidated', invalidated_at: Time.now, owner_type: 'Organization')
      end

      it 'returns repository counts per owner_id for the given owner_ids' do
        counts = Repository.counts_by_owner_ids([1, 2], 'Organization')
        expect(counts).to eq({ 1 => 1, 2 => 1 })
      end
    end
  end

  describe 'api_url' do
    let(:repo) { Repository.new(owner: FactoryBot.create(:org), owner_name: 'travis-ci', name: 'travis-ci') }

    before :each do
      Travis.config.github.api_url = 'https://api.github.com'
    end

    it 'returns the api url for the repository' do
      expect(repo.api_url).to eq('https://api.github.com/repos/travis-ci/travis-ci')
    end
  end

  describe 'source_url' do
    describe 'default source endpoint' do
      let(:repo) { Repository.new(owner: FactoryBot.create(:org), owner_name: 'travis-ci', name: 'travis-ci') }

      before :each do
        Travis.config.github.source_host = nil
      end

      it 'returns the public git source url for a public repository' do
        repo.private = false
        expect(repo.source_url).to eq('git://github.com/travis-ci/travis-ci.git')
      end

      it 'returns the private git source url for a private repository' do
        repo.private = true
        expect(repo.source_url).to eq('git@github.com:travis-ci/travis-ci.git')
      end
    end

    describe 'custom source endpoint' do
      let(:repo) { Repository.new(owner: FactoryBot.create(:org), owner_name: 'travis-ci', name: 'travis-ci') }

      before :each do
        Travis.config.github.source_host = 'localhost'
      end

      it 'returns the private git source url for a public repository' do
        repo.private = false
        expect(repo.source_url).to eq('git@localhost:travis-ci/travis-ci.git')
      end

      it 'returns the private git source url for a private repository' do
        repo.private = true
        expect(repo.source_url).to eq('git@localhost:travis-ci/travis-ci.git')
      end
    end
  end

  describe 'source_host' do
    before :each do
      Travis.config.github.source_host = 'localhost'
    end

    it 'returns the source_host name from Travis.config' do
      expect(Repository.new.source_host).to eq('localhost')
    end
  end

  describe "#last_build" do
    let(:repo) { FactoryBot.create(:repository) }
    let(:attributes) { { repository: repo, state: 'finished' } }
    let(:api_req)    { FactoryBot.create(:request, {event_type: 'api'}) }

    before :each do
      FactoryBot.create(:build, attributes)
      FactoryBot.create(:build, attributes)
    end

    context 'when last build is a push build' do
      before :each do
        @build = FactoryBot.create(:build, attributes)
      end

      it 'returns the most recent build' do
        expect(repo.last_build_on('master').id).to eq(@build.id)
      end
    end

    context 'when last build is an API build' do
      before :each do
        @build = FactoryBot.create(:build, attributes.merge({request: api_req}))
      end

      it 'returns the most recent build' do
        expect(repo.last_build_on('master').id).to eq(@build.id)
      end
    end
  end

  describe '#last_build_on' do
    let(:repo)       { FactoryBot.create(:repository) }
    let(:attributes) { { repository: repo, state: 'finished' } }
    let(:api_req)    { FactoryBot.create(:request, {event_type: 'api'}) }

    before :each do
      FactoryBot.create(:build, attributes)
    end

    context 'when last build is a push build' do
      before :each do
        @build = FactoryBot.create(:build, attributes)
      end

      it 'returns the most recent build' do
        expect(repo.last_build_on('master').id).to eq(@build.id)
      end
    end

    context 'when last build is an API build' do
      before :each do
        @build = FactoryBot.create(:build, attributes.merge({request: api_req}))
      end

      it 'returns the most recent build' do
        expect(repo.last_build_on('master').id).to eq(@build.id)
      end
    end
  end

  describe "keys" do
    let(:repo) { FactoryBot.create(:repository) }
    before { repo.regenerate_key! }

    it "should return the public key" do
      expect(repo.public_key).to eq(repo.key.public_key)
    end
  end

  describe 'branches' do
    let(:repo) { FactoryBot.create(:repository) }

    it 'returns branches for the given repository' do
      %w(master production).each do |branch|
        2.times { FactoryBot.create(:build, repository: repo, commit: FactoryBot.create(:commit, branch: branch)) }
      end
      expect(repo.branches.sort).to eq(%w(master production))
    end

    it 'is empty for empty repository' do
      repo.last_build_id = nil
      repo.save
      Build.delete_all
      expect(repo.branches).to eql []
    end
  end

  describe 'settings' do
    let(:repo) { FactoryBot.build(:repository) }

    it 'adds repository_id to collection records' do
      repo.save

      env_var = repo.settings.env_vars.create(name: 'FOO')
      expect(env_var.repository_id).to eq(repo.id)

      repo.settings.save

      repo.reload

      expect(repo.settings.env_vars.first.repository_id).to eq(repo.id)
    end

    it "is reset on reload" do
      repo.save

      repo.settings = {}
      repo.update_column(:settings, { 'build_pushes' => false }.to_json)
      repo.reload
      expect(repo.settings.build_pushes?).to be false
      repo.update_column(:settings, { 'build_pushes' => true }.to_json)
      repo.reload
      expect(repo.settings.build_pushes?).to be true
    end

    it 'updates settings in the DB' do
      repo.settings = {'build_pushes' => false}
      repo.save

      expect(repo.reload.settings.build_pushes?).to eq(false)

      repo.settings.merge('build_pushes' => true)
      repo.settings.save

      expect(repo.reload.settings.build_pushes?).to eq(true)
    end
  end

  describe 'last_finished_builds_by_branches' do
    let(:repo) { FactoryBot.create(:repository) }

    it 'properly orders branches by last build' do
      repo # load the repo
      Build.delete_all
      one = FactoryBot.create(:build, repository: repo, finished_at: 2.hours.ago, state: 'finished', commit: FactoryBot.create(:commit, branch: '1one'))
      two = FactoryBot.create(:build, repository: repo, finished_at: 1.hours.ago, state: 'finished', commit: FactoryBot.create(:commit, branch: '2two'))

      builds = repo.last_finished_builds_by_branches(1)
      expect(builds).to eq([two])
    end

    it 'retrieves last builds on all branches' do
      repo # load the repo
      Build.delete_all
      old = FactoryBot.create(:build, repository: repo, number: 1, finished_at: 1.hour.ago,      state: 'finished', commit: FactoryBot.create(:commit, branch: 'one'))
      one = FactoryBot.create(:build, repository: repo, number: 2, finished_at: 1.hour.from_now, state: 'finished', commit: FactoryBot.create(:commit, branch: 'one'))
      two = FactoryBot.create(:build, repository: repo, number: 3, finished_at: 1.hour.from_now, state: 'finished', commit: FactoryBot.create(:commit, branch: 'two'))
      three = FactoryBot.create(:build, repository: repo, number: 4, finished_at: 1.hour.from_now, state: 'finished', commit: FactoryBot.create(:commit, branch: 'three'))
      three.update_attribute(:event_type, 'pull_request')

      builds = repo.last_finished_builds_by_branches
      expect(builds.size).to eq(2)
      expect(builds).to include(one)
      expect(builds).to include(two)
      expect(builds).not_to include(old)
    end
  end

  describe '#users_with_permission' do
    it 'returns users with the given permission linked to that repository' do
      repo = FactoryBot.create(:repository)
      other_repo = FactoryBot.create(:repository)

      user_with_permission = FactoryBot.create(:user)
      user_with_permission.permissions.create!(repository: repo, admin: true)

      user_wrong_repo = FactoryBot.create(:user)
      user_wrong_repo.permissions.create!(repository: other_repo, admin: true)

      user_wrong_permission = FactoryBot.create(:user)
      user_wrong_permission.permissions.create!(repository: repo, push: true)

      expect(repo.users_with_permission(:admin)).to include(user_with_permission)
      expect(repo.users_with_permission(:admin)).not_to include(user_wrong_repo)
      expect(repo.users_with_permission(:admin)).not_to include(user_wrong_permission)
    end
  end

  describe '#settings' do
    let(:repo)   { FactoryBot.create(:repository, name: 'foobarbaz') }

    it 'ensures settings are always a hash' do
      repo.settings = {'build_pushes' => false}.to_json
      repo.save

      expect(JSON.parse(repo.reload.attributes['settings'])).to be_a(Hash)

      repo.settings = {'build_pushes' => false}
      repo.save

      expect(JSON.parse(repo.reload.attributes['settings'])).to be_a(Hash)
    end
  end
end

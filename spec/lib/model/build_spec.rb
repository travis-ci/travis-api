describe Build do
  before { DatabaseCleaner.clean_with :truncation }

  let(:repository) { FactoryBot.create(:repository_without_last_build) }

  it 'caches matrix ids' do
    build = FactoryBot.create(:build, config: { rvm: ['1.9.3', '2.0.0'] })
    expect(build.cached_matrix_ids).to eq(build.matrix_ids)
  end

  it 'returns nil if cached_matrix_ids are not set' do
    build = FactoryBot.create(:build)
    build.update_column(:cached_matrix_ids, nil)
    expect(build.reload.cached_matrix_ids).to be_nil
  end

  it 'is cancelable if at least one job is cancelable' do
    jobs = [FactoryBot.build(:test), FactoryBot.build(:test)]
    allow(jobs.first).to receive(:cancelable?).and_return(true)
    allow(jobs.second).to receive(:cancelable?).and_return(false)

    build = FactoryBot.build(:build, matrix: jobs)
    expect(build).to be_cancelable
  end

  it 'is not cancelable if none of the jobs are cancelable' do
    jobs = [FactoryBot.build(:test), FactoryBot.build(:test)]
    allow(jobs.first).to receive(:cancelable?).and_return(false)
    allow(jobs.second).to receive(:cancelable?).and_return(false)

    build = FactoryBot.build(:build, matrix: jobs)
    expect(build).not_to be_cancelable
  end

  describe '#secure_env_enabled?' do
    it 'returns true if we\'re not dealing with pull request' do
      build = FactoryBot.build(:build)
      allow(build).to receive(:pull_request?).and_return(false)
      expect(build.secure_env_enabled?).to be true
    end

    it 'returns true if pull request is from the same repository' do
      build = FactoryBot.build(:build)
      allow(build).to receive(:pull_request?).and_return(true)
      allow(build).to receive(:same_repo_pull_request?).and_return(true)
      expect(build.secure_env_enabled?).to be true
    end

    it 'returns false if pull request is not from the same repository' do
      build = FactoryBot.build(:build)
      allow(build).to receive(:pull_request?).and_return(true)
      allow(build).to receive(:same_repo_pull_request?).and_return(false)
      expect(build.secure_env_enabled?).to be false
    end
  end

  describe 'class methods' do
    describe 'recent' do
      it 'returns recent finished builds ordered by id descending' do
        FactoryBot.create(:build, state: 'passed')
        FactoryBot.create(:build, state: 'failed')
        FactoryBot.create(:build, state: 'created')

        expect(Build.recent.all.map(&:state)).to eq([:failed, :passed])
      end
    end

    describe 'was_started' do
      it 'returns builds that are either started or finished' do
        FactoryBot.create(:build, state: 'passed')
        FactoryBot.create(:build, state: 'started')
        FactoryBot.create(:build, state: 'created')

        expect(Build.was_started.map(&:state).sort).to eq([:passed, :started])
      end
    end

    describe 'on_branch' do
      it 'returns builds that are on any of the given branches' do
        FactoryBot.create(:build, commit: FactoryBot.create(:commit, branch: 'master'))
        FactoryBot.create(:build, commit: FactoryBot.create(:commit, branch: 'develop'))
        FactoryBot.create(:build, commit: FactoryBot.create(:commit, branch: 'feature'))

        expect(Build.on_branch('master,develop').map(&:commit).map(&:branch).sort).to eq(['develop', 'master'])
      end

      it 'does not include pull requests' do
        FactoryBot.create(:build, commit: FactoryBot.create(:commit, branch: 'no-pull'), request: FactoryBot.create(:request, event_type: 'pull_request'))
        FactoryBot.create(:build, commit: FactoryBot.create(:commit, branch: 'no-pull'), request: FactoryBot.create(:request, event_type: 'push'))
        expect(Build.on_branch('no-pull').count).to eq(1)
      end
    end

    describe 'older_than' do
      before do
        5.times { |i| FactoryBot.create(:build, number: i) }
        allow(Build).to receive(:per_page).and_return(2)
      end

      context "when a Build is passed in" do
        subject { Build.older_than(Build.new(number: 3)) }

        it "should limit the results" do
          expect(subject.size).to eq(2)
        end

        it "should return older than the passed build" do
          expect(subject.map(&:number)).to eq(['2', '1'])
        end
      end

      context "when a number is passed in" do
        subject { Build.older_than(3) }

        it "should limit the results" do
          expect(subject.size).to eq(2)
        end

        it "should return older than the passed build" do
          expect(subject.map(&:number)).to eq(['2', '1'])
        end
      end

      context "when not passing a build" do
        subject { Build.older_than() }

        it "should limit the results" do
          expect(subject.size).to eq(2)
        end
      end
    end

    describe 'paged' do
      it 'limits the results to the `per_page` value' do
        3.times { FactoryBot.create(:build) }
        allow(Build).to receive(:per_page).and_return(1)

        expect(Build.descending.paged({}).size).to eq(1)
      end

      it 'uses an offset' do
        3.times { |i| FactoryBot.create(:build) }
        allow(Build).to receive(:per_page).and_return(1)

        builds = Build.descending.paged({page: 2})
        expect(builds.size).to eq(1)
        expect(builds.first.number).to eq('2')
      end
    end

    describe 'pushes' do
      before do
        FactoryBot.create(:build)
        FactoryBot.create(:build, request: FactoryBot.create(:request, event_type: 'pull_request'))
      end

      it "returns only builds which have Requests with an event_type of push" do
        expect(Build.pushes.all.count).to eq(1)
      end
    end

    describe 'pull_requests' do
      before do
        FactoryBot.create(:build)
        FactoryBot.create(:build, request: FactoryBot.create(:request, event_type: 'pull_request'))
      end

      it "returns only builds which have Requests with an event_type of pull_request" do
        expect(Build.pull_requests.all.count).to eq(1)
      end
    end
  end

  describe 'creation' do
    describe 'previous_state' do
      it 'is set to the last finished build state on the same branch' do
        FactoryBot.create(:build, state: 'failed')
        expect(FactoryBot.create(:build).reload.previous_state).to eq('failed')
      end

      it 'is set to the last finished build state on the same branch (disregards non-finished builds)' do
        FactoryBot.create(:build, state: 'failed')
        FactoryBot.create(:build, state: 'started')
        expect(FactoryBot.create(:build).reload.previous_state).to eq('failed')
      end

      it 'is set to the last finished build state on the same branch (disregards other branches)' do
        FactoryBot.create(:build, state: 'failed')
        FactoryBot.create(:build, state: 'passed', commit: FactoryBot.create(:commit, branch: 'something'))
        expect(FactoryBot.create(:build).reload.previous_state).to eq('failed')
      end
    end

    it "updates the last_build on the build's branch" do
      build = FactoryBot.create(:build)
      branch = Branch.where(repository_id: build.repository_id, name: build.branch).first
      expect(branch.last_build).to eq(build)
    end
  end

  describe 'instance methods' do
    it 'sets its number to the next build number on creation' do
      1.upto(3) do |number|
        expect(FactoryBot.create(:build).reload.number).to eq(number.to_s)
      end
    end

    it 'sets previous_state to nil if no last build exists on the same branch' do
      build = FactoryBot.create(:build, commit: FactoryBot.create(:commit, branch: 'master'))
      expect(build.reload.previous_state).to eq(nil)
    end

    it 'sets previous_state to the result of the last build on the same branch if exists' do
      build = FactoryBot.create(:build, state: :canceled, commit: FactoryBot.create(:commit, branch: 'master'))
      build = FactoryBot.create(:build, commit: FactoryBot.create(:commit, branch: 'master'))
      expect(build.reload.previous_state).to eq('canceled')
    end

    describe 'config' do
      it 'defaults to a hash with language and os set' do
        build = Build.new(repository: Repository.new(owner: User.new))
        expect(build.config).to eq({ language: 'ruby', group: 'stable', dist: 'precise', os: 'linux' })
      end

      it 'deep_symbolizes keys on write' do
        build = FactoryBot.create(:build, config: { 'foo' => { 'bar' => 'bar' } })
        expect(build.config[:foo]).to eq({ bar: 'bar' })
      end

      it 'downcases the language on config' do
        build = FactoryBot.create(:build, config: { language: "PYTHON" })
        expect(Build.last.config[:language]).to eq("python")
      end

      it 'sets ruby as default language' do
        build = FactoryBot.create(:build, config: { 'foo' => { 'bar' => 'bar' } })
        expect(Build.last.config[:language]).to eq("ruby")
      end
    end

    describe :pending? do
      it 'returns true if the build is finished' do
        build = FactoryBot.create(:build, state: :finished)
        expect(build.pending?).to be false
      end

      it 'returns true if the build is not finished' do
        build = FactoryBot.create(:build, state: :started)
        expect(build.pending?).to be true
      end
    end

    describe :passed? do
      it 'passed? returns true if state equals :passed' do
        build = FactoryBot.create(:build, state: :passed)
        expect(build.passed?).to be true
      end

      it 'passed? returns true if result does not equal :passed' do
        build = FactoryBot.create(:build, state: :failed)
        expect(build.passed?).to be false
      end
    end

    describe :color do
      it 'returns "green" if the build has passed' do
        build = FactoryBot.create(:build, state: :passed)
        expect(build.color).to eq('green')
      end

      it 'returns "red" if the build has failed' do
        build = FactoryBot.create(:build, state: :failed)
        expect(build.color).to eq('red')
      end

      it 'returns "yellow" if the build is pending' do
        build = FactoryBot.create(:build, state: :started)
        expect(build.color).to eq('yellow')
      end
    end

    it 'saves event_type before create' do
      build = FactoryBot.create(:build,  request: FactoryBot.create(:request, event_type: 'pull_request'))
      expect(build.event_type).to eq('pull_request')

      build = FactoryBot.create(:build,  request: FactoryBot.create(:request, event_type: 'push'))
      expect(build.event_type).to eq('push')
    end

    it 'saves branch before create' do
      build = FactoryBot.create(:build,  commit: FactoryBot.create(:commit, branch: 'development'))
      expect(build.branch).to eq('development')
    end

    describe 'reset' do
      let(:build) { FactoryBot.create(:build, state: 'finished') }

      before :each do
        build.matrix.each { |job| allow(job).to receive(:reset) }
      end

      it 'sets the state to :created' do
        build.reset
        expect(build.state).to eq(:created)
      end

      it 'resets related attributes' do
        build.reset
        expect(build.duration).to be_nil
        expect(build.finished_at).to be_nil
      end

      it 'resets each job if :reset_matrix is given' do
        build.matrix.each { |job| expect(job).to receive(:reset) }
        build.reset(reset_matrix: true)
      end

      it 'does not reset jobs if :reset_matrix is not given' do
        build.matrix.each { |job| expect(job).not_to receive(:reset) }
        build.reset
      end
    end
  end
end

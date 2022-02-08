describe Repository::StatusImage do
  let(:cache)    { double('states cache', fetch: nil, write: nil, fetch_state: nil) }
  let!(:request) { FactoryBot.create(:request, event_type: 'push', repository: repo) }
  let!(:build)   { FactoryBot.create(:build, repository: repo, request: request, state: :passed) }
  let(:repo)     { FactoryBot.create(:repository_without_last_build) }

  before do
    allow_any_instance_of(described_class).to receive(:cache).and_return(cache)
    allow_any_instance_of(described_class).to receive(:cache_enabled?).and_return(true)
  end

  describe('with cache') do
    it 'tries to get state from cache first' do
      image = described_class.new(repo, 'foobar')
      expect(cache).to receive(:fetch_state).with(repo.id, 'foobar').and_return(:passed)

      expect(image.result).to eq(:passing)
    end

    it 'saves state to the cache if it needs to be fetched from the db' do
      image = described_class.new(repo, 'master')
      expect(cache).to receive(:fetch_state).with(repo.id, 'master').and_return(nil)
      expect(cache).to receive(:write).with(repo.id, 'master', build)

      expect(image.result).to eq(:passing)
    end

    it 'saves state of the build to the cache with its branch even if branch is not given' do
      image = described_class.new(repo, nil)
      expect(cache).to receive(:fetch_state).with(repo.id, nil).and_return(nil)
      expect(cache).to receive(:write).with(repo.id, 'master', build)

      expect(image.result).to eq(:passing)
    end

    it 'handles cache failures gracefully' do
      image = described_class.new(repo, nil)
      expect(cache).to receive(:fetch_state).and_raise(Travis::StatesCache::CacheError)
      expect {
        expect(image.result).to eq(:passing)
      }.to_not raise_error
    end
  end

  describe 'given no branch' do
    it 'returns the status of the last finished build' do
      image = described_class.new(repo, nil)
      expect(image.result).to eq(:passing)
    end

    it 'returns :failing if the status of the last finished build is failed' do
      build.update(state: :failed)
      image = described_class.new(repo, nil)
      expect(image.result).to eq(:failing)
    end

    it 'returns :error if the status of the last finished build is errored' do
      build.update(state: :errored)
      image = described_class.new(repo, nil)
      expect(image.result).to eq(:error)
    end

    it 'returns :canceled if the status of the last finished build is canceled' do
      build.update(state: 'canceled')
      image = described_class.new(repo, nil)
      expect(image.result).to eq(:canceled)
    end

    it 'returns :unknown if the status of the last finished build is unknown' do
      build.update(state: :created)
      image = described_class.new(repo, nil)
      expect(image.result).to eq(:unknown)
    end
  end

  describe 'given a branch' do
    it 'returns :passed if the last build on that branch has passed' do
      build.update(state: :passed, branch: 'master')
      image = described_class.new(repo, 'master')
      expect(image.result).to eq(:passing)
    end

    it 'returns :failed if the last build on that branch has failed' do
      build.update(state: :failed, branch: 'develop')
      image = described_class.new(repo, 'develop')
      expect(image.result).to eq(:failing)
    end

    it 'returns :error if the last build on that branch has errored' do
      build.update(state: :errored, branch: 'develop')
      image = described_class.new(repo, 'develop')
      expect(image.result).to eq(:error)
    end

    it 'returns :canceled if the last build on that branch was canceled' do
      build.update(state: :canceled, branch: 'develop')
      image = described_class.new(repo, 'develop')
      expect(image.result).to eq(:canceled)
    end

    context "when the branch has a cron and push build" do
      context "the last push build failed" do
        let!(:last_push_build) { FactoryBot.create(:build, branch: "master", repository: repo, request: request, state: :failed) }
        context "the last cron build, after the last push, passed" do
          it "returns :passed" do
            last_cron_build = FactoryBot.create(:build, branch: "master", repository: repo, request: FactoryBot.create(:request, event_type: "cron", repository: repo), state: :passed)

            image = described_class.new(repo, "master")
            expect(image.result).to eq(:passing)
          end
        end
      end
    end
  end
end

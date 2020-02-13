describe 'Job::Queue' do
  def queue(*args)
    Job::Queue.new(*args)
  end

  let(:the_past) { Time.parse("1982-06-23") }
  let(:recently) { 7.days.ago }

  before do
    Travis.config.queues = [
      { queue: 'builds.rails', slug: 'rails/rails' },
      { queue: 'builds.mac_osx', os: 'osx' },
      { queue: 'builds.docker', sudo: false },
      { queue: 'builds.gce', services: %w(docker) },
      { queue: 'builds.gce', dist: 'trusty' },
      { queue: 'builds.cloudfoundry', owner: 'cloudfoundry' },
      { queue: 'builds.clojure', language: 'clojure' },
      { queue: 'builds.erlang', language: 'erlang' },
    ]
    Job::Queue.instance_variable_set(:@queues, nil)
    Job::Queue.instance_variable_set(:@default, nil)
    allow(Travis::Features).to receive(:owner_active?).and_return(true)
    allow(Travis::Github::Education).to receive(:education_queue?).and_return(false)
  end

  after do
    Travis.config.default_queue = 'builds.linux'
  end

  it 'returns builds.linux as the default queue' do
    expect(Job::Queue.default.name).to eq('builds.linux')
  end

  it 'returns builds.common as the default queue if configured to in Travis.config' do
    Travis.config.default_queue = 'builds.common'
    expect(Job::Queue.default.name).to eq('builds.common')
  end

  describe 'Queue.sudo_detected?' do
    [
      [{ script: 'sudo echo' }, true],
      [{ bogus: 'sudo echo' }, false],
      [{ before_install: ['# no sudo', 'ping -c 1 google.com'] }, true],
      [{ before_install: ['docker run busybox echo whatever'] }, true],
      [{ before_script: ['echo ; echo ; echo ; sudo echo ; echo'] }, true],
      [{ install: '# no sudo needed here' }, false],
      [{ install: true }, false],
    ].each do |config, expected|
      it "returns #{expected} for #{config}" do
        expect(Job::Queue.sudo_detected?(config)).to eq(expected)
      end
    end
  end

  describe 'Queue.for' do
    it 'returns the default build queue when neither slug or language match the given configuration hash' do
      job = double('job', :config => {}, :repository => double('repository', :owner_name => 'travis-ci', :name => 'travis-ci', :owner => double, :created_at => the_past))
      expect(Job::Queue.for(job).name).to eq('builds.linux')
    end

    it 'returns the queue when slug matches the given configuration hash' do
      job = double('job', :config => {}, :repository => double('repository', :owner_name => 'rails', :name => 'rails', :owner => double, :created_at => the_past))
      expect(Job::Queue.for(job).name).to eq('builds.rails')
    end

    it 'returns the queue when language matches the given configuration hash' do
      job = double('job', :config => { :language => 'clojure' }, :repository => double('repository', :owner_name => 'travis-ci', :name => 'travis-ci', :owner => double, :created_at => the_past))
      expect(Job::Queue.for(job).name).to eq('builds.clojure')
    end

    it 'returns the queue when the owner matches the given configuration hash' do
      job = double('job', :config => {}, :repository => double('repository', :owner_name => 'cloudfoundry', :name => 'bosh', :owner => double, :created_at => the_past))
      expect(Job::Queue.for(job).name).to eq('builds.cloudfoundry')
    end

    it 'returns the queue when sudo requirements matches the given configuration hash' do
      job = double('job', :config => { sudo: false }, :repository => double('repository', :owner_name => 'markronson', :name => 'recordcollection', :owner => double, :created_at => the_past))
      expect(Job::Queue.for(job).name).to eq('builds.docker')
    end

    it 'returns the docker queue by default for educational repositories' do
      allow(Travis::Github::Education).to receive(:education_queue?).and_return(true)
      owner = double('owner', :education => true)
      job = double('job', :config => { }, :repository => double('repository', :owner_name => 'markronson', :name => 'recordcollection', :owner => owner, :created_at => the_past))
      expect(Job::Queue.for(job).name).to eq('builds.docker')
    end

    it 'returns the queue matching configuration for educational repository' do
      allow(Travis::Github::Education).to receive(:education_queue?).and_return(true)
      owner = double('owner', :education => true)
      job = double('job', :config => { :os => 'osx' }, :repository => double('repository', :owner_name => 'markronson', :name => 'recordcollection', :owner => owner, :created_at => the_past))
      expect(Job::Queue.for(job).name).to eq('builds.mac_osx')
    end

    it 'handles language being passed as an array gracefully' do
      job = double('job', :config => { :language => ['clojure'] }, :repository => double('repository', :owner_name => 'travis-ci', :name => 'travis-ci', :owner => double, :created_at => the_past))
      expect(Job::Queue.for(job).name).to eq('builds.clojure')
    end

    context 'when "os" value matches the given configuration hash' do
      it 'returns the matching queue' do
        job = double('job', :config => { :os => 'osx'}, :repository => double('travis-core', :owner_name => 'travis-ci', :name => 'bosh', :owner => double, :created_at => the_past))
        expect(Job::Queue.for(job).name).to eq('builds.mac_osx')
      end

      it 'returns the matching queue when language is also given' do
        job = double('job', :config => {:language => 'clojure', :os => 'osx'}, :repository => double('travis-core', :owner_name => 'travis-ci', :name => 'bosh', :owner => double, :created_at => the_past))
        expect(Job::Queue.for(job).name).to eq('builds.mac_osx')
      end
    end

    context 'when "services" value matches the given configuration hash' do
      it 'returns the matching queue' do
        job = double('job', config: { services: %w(redis docker postgresql) }, repository: double('travis-core', owner_name: 'travis-ci', name: 'bosh', owner: double, created_at: the_past))
        expect(Job::Queue.for(job).name).to eq('builds.gce')
      end

      it 'returns the matching queue when language is also given' do
        job = double('job', config: { language: 'clojure', services: %w(redis docker postgresql) }, repository: double('travis-core', owner_name: 'travis-ci', name: 'bosh', owner: double, created_at: the_past))
        expect(Job::Queue.for(job).name).to eq('builds.gce')
      end
    end

    context 'when "docker_default_queue" feature is active' do
      before do
        allow(Travis::Features).to receive(:feature_active?).with(:docker_default_queue).and_return(true)
        allow(Travis::Features).to receive(:feature_active?).with(:education).and_return(true)
      end

      it 'returns "builds.docker" when sudo: nil and the repo created_at is nil' do
        job = double('job', :config => { }, :repository => double('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => double, :created_at => nil))
        expect(Job::Queue.for(job).name).to eq('builds.docker')
      end

      it 'returns "builds.docker" when sudo: nil and the repo created_at is after cutoff' do
        Travis.config.docker_default_queue_cutoff = recently.to_s
        job = double('job', :config => { }, :repository => double('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => double, :created_at => Time.now))
        expect(Job::Queue.for(job).name).to eq('builds.docker')
      end

      it 'returns "builds.linux" when sudo: nil and the repo created_at is before cutoff' do
        Travis.config.docker_default_queue_cutoff = recently.to_s
        job = double('job', :config => { }, :repository => double('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => double, :created_at => recently - 7.days))
        expect(Job::Queue.for(job).name).to eq('builds.linux')
      end

      it 'returns "builds.linux" when sudo: nil and the repo created_at is after cutoff and sudo is detected' do
        Travis.config.docker_default_queue_cutoff = recently.to_s
        job = double('job', :config => { script: 'sudo echo whatever' }, :repository => double('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => double, :created_at => recently - 7.days))
        expect(Job::Queue.for(job).name).to eq('builds.linux')
      end

      it 'returns "builds.docker" when sudo: false and the repo created_at is nil' do
        job = double('job', :config => { sudo: false }, :repository => double('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => double, :created_at => nil))
        expect(Job::Queue.for(job).name).to eq('builds.docker')
      end

      it 'returns "builds.docker" when sudo: false and the repo created_at is after cutoff' do
        Travis.config.docker_default_queue_cutoff = recently.to_s
        job = double('job', :config => { sudo: false }, :repository => double('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => double, :created_at => Time.now))
        expect(Job::Queue.for(job).name).to eq('builds.docker')
      end

      it 'returns "builds.docker" when sudo: false and the repo created_at is before cutoff' do
        Travis.config.docker_default_queue_cutoff = recently.to_s
        job = double('job', :config => { sudo: false }, :repository => double('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => double, :created_at => recently - 7.days))
        expect(Job::Queue.for(job).name).to eq('builds.docker')
      end

      [true, 'required'].each do |sudo|
        it %{returns "builds.linux" when sudo: #{sudo} and the repo created_at is nil} do
          Travis.config.docker_default_queue_cutoff = recently.to_s
          job = double('job', :config => { sudo: sudo }, :repository => double('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => double, :created_at => nil))
          expect(Job::Queue.for(job).name).to eq('builds.linux')
        end

        it %{returns "builds.linux" when sudo: #{sudo} and the repo created_at is after cutoff} do
          Travis.config.docker_default_queue_cutoff = recently.to_s
          job = double('job', :config => { sudo: sudo }, :repository => double('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => double, :created_at => nil))
          expect(Job::Queue.for(job).name).to eq('builds.linux')
        end

        it %{returns "builds.linux" when sudo: #{sudo} and the repo created_at is before cutoff} do
          Travis.config.docker_default_queue_cutoff = recently.to_s
          job = double('job', :config => { sudo: sudo }, :repository => double('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => double, :created_at => nil))
          expect(Job::Queue.for(job).name).to eq('builds.linux')
        end
      end
    end
  end

  context 'when "sudo" value matches the given configuration hash' do
    it 'returns the matching queue' do
      job = double('job', config: { sudo: false }, repository: double('travis-core', owner_name: 'travis-ci', name: 'travis-core', owner: double, :created_at => the_past))
      expect(Job::Queue.for(job).name).to eq('builds.docker')
    end

    it 'returns the matching queue when language is also given' do
      job = double('job', config: { language: 'clojure', sudo: false }, repository: double('travis-core', owner_name: 'travis-ci', name: 'travis-core', owner: double, :created_at => the_past))
      expect(Job::Queue.for(job).name).to eq('builds.docker')
    end
  end

  describe 'Queue.queues' do
    it 'returns an array of Queues for the config hash' do
      rails, _, docker, _, _, cloudfoundry, clojure, _ = Job::Queue.send(:queues)

      expect(rails.name).to eq('builds.rails')
      expect(rails.attrs[:slug]).to eq('rails/rails')

      expect(docker.name).to eq('builds.docker')
      expect(docker.attrs[:sudo]).to eq(false)

      expect(cloudfoundry.name).to eq('builds.cloudfoundry')
      expect(cloudfoundry.attrs[:owner]).to eq('cloudfoundry')

      expect(clojure.name).to eq('builds.clojure')
      expect(clojure.attrs[:language]).to eq('clojure')
    end
  end

  describe 'matches?' do
    it "returns false when neither of slug or language match" do
      queue = queue('builds.linux', {})
      expect(queue.matches?(double('job', repository: double('repository', owner_name: 'foo', name: 'bar', owner: nil), config: { language: 'COBOL' }))).to be false
    end

    it "returns true when the given owner matches" do
      queue = queue('builds.cloudfoundry', { owner: 'cloudfoundry' })
      expect(queue.matches?(double('job', repository: double('repository', owner_name: 'cloudfoundry', name: 'bosh', owner: nil), config: {}))).to be true
    end

    it "returns true when the given slug matches" do
      queue = queue('builds.rails', { slug: 'rails/rails' })
      expect(queue.matches?(double('job', repository: double('repository', owner_name: 'rails', name: 'rails', owner: nil), config: {}))).to be true
    end

    it "returns true when the given language matches" do
      queue = queue('builds.linux', { language: 'clojure' })
      expect(queue.matches?(double('job', repository: double('repository', owner_name: nil, name: nil, owner: nil), config: { language: 'clojure' }))).to be true
    end

    it 'returns true when os is missing' do
      queue = queue('builds.linux', { language: 'clojure' })
      expect(queue.matches?(double('job', repository: double('repository', owner_name: nil, name: nil, owner: nil), config: { language: 'clojure' }))).to be true
    end

    it 'returns true when sudo is false' do
      queue = queue('builds.docker', { sudo: false })
      expect(queue.matches?(double('job', repository: double('repository', owner_name: nil, name: nil, owner: nil), config: { sudo: false }))).to be true
    end

    it 'returns false when sudo is true' do
      queue = queue('builds.docker', { sudo: false })
      expect(queue.matches?(double('job', repository: double('repository', owner_name: nil, name: nil, owner: nil), config: { sudo: true }))).to be false
    end

    it 'returns false when sudo is not specified' do
      queue = queue('builds.docker', { sudo: false })
      expect(queue.matches?(double('job', repository: double('repository', owner_name: nil, name: nil, owner: nil), config: {}))).to be false
    end

    it 'returns true when dist matches' do
      queue = queue('builds.gce', { dist: 'trusty' })
      expect(queue.matches?(double('job', repository: double('repository', owner_name: nil, name: nil, owner: nil), config: { dist: 'trusty' }))).to be true
    end

    it 'returns false when dist does not match' do
      queue = queue('builds.docker', { dist: 'precise' })
      expect(queue.matches?(double('job', repository: double('repository', owner_name: nil, name: nil, owner: nil), config: { dist: 'trusty' }))).to be false
    end

    it 'returns true when osx_image matches' do
      queue = queue('builds.mac_beta', { osx_image: 'beta' })
      expect(queue.matches?(double('job', repository: double('repository', owner_name: nil, name: nil, owner: nil), config: { osx_image: 'beta' }))).to be true
    end

    it 'returns false when osx_image does not match' do
      queue = queue('builds.mac_stable', { osx_image: 'stable' })
      expect(queue.matches?(double('job', repository: double('repository', owner_name: nil, name: nil, owner: nil), config: { osx_image: 'beta' }))).to be false
    end

    it 'returns true when services match' do
      queue = queue('builds.gce', { services: %w(docker) })
      expect(queue.matches?(double('job', repository: double('repository', owner_name: nil, name: nil, owner: nil), config: { services: %w(redis docker postgresql) }))).to be true
    end

    it 'returns false when services do not match' do
      queue = queue('builds.gce', { services: %w(docker) })
      expect(queue.matches?(double('job', repository: double('repository', owner_name: nil, name: nil, owner: nil), config: { services: %w(redis postgresql) }))).to be false
    end

    it 'returns false if no valid matchers are specified' do
      queue = queue('builds.invalid', { foobar_donotmatch: true })
      expect(queue.matches?(double('job', repository: double('repository', owner_name: nil, name: nil, owner: nil), config: {}))).to be false
    end

    it 'returns true for percentage: 100' do
      queue = queue('builds.always', { percentage: 100 })
      expect(queue.matches?(double('job', repository: double('repository', owner_name: nil, name: nil, owner: nil), config: {}))).to be true
    end

    it 'returns false for percentage: 0' do
      queue = queue('builds.always', { percentage: 0 })
      expect(queue.matches?(double('job', repository: double('repository', owner_name: nil, name: nil, owner: nil), config: {}))).to be false
    end
  end
end

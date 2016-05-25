require 'spec_helper'

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
    Travis::Features.stubs(:owner_active?).returns(true)
    Travis::Github::Education.stubs(:education_queue?).returns(false)
  end

  after do
    Travis.config.default_queue = 'builds.linux'
  end

  it 'returns builds.linux as the default queue' do
    Job::Queue.default.name.should == 'builds.linux'
  end

  it 'returns builds.common as the default queue if configured to in Travis.config' do
    Travis.config.default_queue = 'builds.common'
    Job::Queue.default.name.should == 'builds.common'
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
        Job::Queue.sudo_detected?(config).should == expected
      end
    end
  end

  describe 'Queue.for' do
    it 'returns the default build queue when neither slug or language match the given configuration hash' do
      job = stub('job', :config => {}, :repository => stub('repository', :owner_name => 'travis-ci', :name => 'travis-ci', :owner => stub, :created_at => the_past))
      Job::Queue.for(job).name.should == 'builds.linux'
    end

    it 'returns the queue when slug matches the given configuration hash' do
      job = stub('job', :config => {}, :repository => stub('repository', :owner_name => 'rails', :name => 'rails', :owner => stub, :created_at => the_past))
      Job::Queue.for(job).name.should == 'builds.rails'
    end

    it 'returns the queue when language matches the given configuration hash' do
      job = stub('job', :config => { :language => 'clojure' }, :repository => stub('repository', :owner_name => 'travis-ci', :name => 'travis-ci', :owner => stub, :created_at => the_past))
      Job::Queue.for(job).name.should == 'builds.clojure'
    end

    it 'returns the queue when the owner matches the given configuration hash' do
      job = stub('job', :config => {}, :repository => stub('repository', :owner_name => 'cloudfoundry', :name => 'bosh', :owner => stub, :created_at => the_past))
      Job::Queue.for(job).name.should == 'builds.cloudfoundry'
    end

    it 'returns the queue when sudo requirements matches the given configuration hash' do
      job = stub('job', :config => { sudo: false }, :repository => stub('repository', :owner_name => 'markronson', :name => 'recordcollection', :owner => stub, :created_at => the_past))
      Job::Queue.for(job).name.should == 'builds.docker'
    end

    it 'returns the docker queue by default for educational repositories' do
      Travis::Github::Education.stubs(:education_queue?).returns(true)
      owner = stub('owner', :education => true)
      job = stub('job', :config => { }, :repository => stub('repository', :owner_name => 'markronson', :name => 'recordcollection', :owner => owner, :created_at => the_past))
      Job::Queue.for(job).name.should == 'builds.docker'
    end

    it 'returns the queue matching configuration for educational repository' do
      Travis::Github::Education.stubs(:education_queue?).returns(true)
      owner = stub('owner', :education => true)
      job = stub('job', :config => { :os => 'osx' }, :repository => stub('repository', :owner_name => 'markronson', :name => 'recordcollection', :owner => owner, :created_at => the_past))
      Job::Queue.for(job).name.should == 'builds.mac_osx'
    end

    it 'handles language being passed as an array gracefully' do
      job = stub('job', :config => { :language => ['clojure'] }, :repository => stub('repository', :owner_name => 'travis-ci', :name => 'travis-ci', :owner => stub, :created_at => the_past))
      Job::Queue.for(job).name.should == 'builds.clojure'
    end

    context 'when "os" value matches the given configuration hash' do
      it 'returns the matching queue' do
        job = stub('job', :config => { :os => 'osx'}, :repository => stub('travis-core', :owner_name => 'travis-ci', :name => 'bosh', :owner => stub, :created_at => the_past))
        Job::Queue.for(job).name.should == 'builds.mac_osx'
      end

      it 'returns the matching queue when language is also given' do
        job = stub('job', :config => {:language => 'clojure', :os => 'osx'}, :repository => stub('travis-core', :owner_name => 'travis-ci', :name => 'bosh', :owner => stub, :created_at => the_past))
        Job::Queue.for(job).name.should == 'builds.mac_osx'
      end
    end

    context 'when "services" value matches the given configuration hash' do
      it 'returns the matching queue' do
        job = stub('job', config: { services: %w(redis docker postgresql) }, repository: stub('travis-core', owner_name: 'travis-ci', name: 'bosh', owner: stub, created_at: the_past))
        Job::Queue.for(job).name.should == 'builds.gce'
      end

      it 'returns the matching queue when language is also given' do
        job = stub('job', config: { language: 'clojure', services: %w(redis docker postgresql) }, repository: stub('travis-core', owner_name: 'travis-ci', name: 'bosh', owner: stub, created_at: the_past))
        Job::Queue.for(job).name.should == 'builds.gce'
      end
    end

    context 'when "docker_default_queue" feature is active' do
      before do
        Travis::Features.stubs(:feature_active?).with(:docker_default_queue).returns(true)
        Travis::Features.stubs(:feature_active?).with(:education).returns(true)
      end

      it 'returns "builds.docker" when sudo: nil and the repo created_at is nil' do
        job = stub('job', :config => { }, :repository => stub('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => stub, :created_at => nil))
        Job::Queue.for(job).name.should == 'builds.docker'
      end

      it 'returns "builds.docker" when sudo: nil and the repo created_at is after cutoff' do
        Travis.config.docker_default_queue_cutoff = recently.to_s
        job = stub('job', :config => { }, :repository => stub('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => stub, :created_at => Time.now))
        Job::Queue.for(job).name.should == 'builds.docker'
      end

      it 'returns "builds.linux" when sudo: nil and the repo created_at is before cutoff' do
        Travis.config.docker_default_queue_cutoff = recently.to_s
        job = stub('job', :config => { }, :repository => stub('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => stub, :created_at => recently - 7.days))
        Job::Queue.for(job).name.should == 'builds.linux'
      end

      it 'returns "builds.linux" when sudo: nil and the repo created_at is after cutoff and sudo is detected' do
        Travis.config.docker_default_queue_cutoff = recently.to_s
        job = stub('job', :config => { script: 'sudo echo whatever' }, :repository => stub('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => stub, :created_at => recently - 7.days))
        Job::Queue.for(job).name.should == 'builds.linux'
      end

      it 'returns "builds.docker" when sudo: false and the repo created_at is nil' do
        job = stub('job', :config => { sudo: false }, :repository => stub('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => stub, :created_at => nil))
        Job::Queue.for(job).name.should == 'builds.docker'
      end

      it 'returns "builds.docker" when sudo: false and the repo created_at is after cutoff' do
        Travis.config.docker_default_queue_cutoff = recently.to_s
        job = stub('job', :config => { sudo: false }, :repository => stub('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => stub, :created_at => Time.now))
        Job::Queue.for(job).name.should == 'builds.docker'
      end

      it 'returns "builds.docker" when sudo: false and the repo created_at is before cutoff' do
        Travis.config.docker_default_queue_cutoff = recently.to_s
        job = stub('job', :config => { sudo: false }, :repository => stub('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => stub, :created_at => recently - 7.days))
        Job::Queue.for(job).name.should == 'builds.docker'
      end

      [true, 'required'].each do |sudo|
        it %{returns "builds.linux" when sudo: #{sudo} and the repo created_at is nil} do
          Travis.config.docker_default_queue_cutoff = recently.to_s
          job = stub('job', :config => { sudo: sudo }, :repository => stub('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => stub, :created_at => nil))
          Job::Queue.for(job).name.should == 'builds.linux'
        end

        it %{returns "builds.linux" when sudo: #{sudo} and the repo created_at is after cutoff} do
          Travis.config.docker_default_queue_cutoff = recently.to_s
          job = stub('job', :config => { sudo: sudo }, :repository => stub('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => stub, :created_at => nil))
          Job::Queue.for(job).name.should == 'builds.linux'
        end

        it %{returns "builds.linux" when sudo: #{sudo} and the repo created_at is before cutoff} do
          Travis.config.docker_default_queue_cutoff = recently.to_s
          job = stub('job', :config => { sudo: sudo }, :repository => stub('repository', :owner_name => 'travis-ci', :name => 'travis-core', :owner => stub, :created_at => nil))
          Job::Queue.for(job).name.should == 'builds.linux'
        end
      end
    end
  end

  context 'when "sudo" value matches the given configuration hash' do
    it 'returns the matching queue' do
      job = stub('job', config: { sudo: false }, repository: stub('travis-core', owner_name: 'travis-ci', name: 'travis-core', owner: stub, :created_at => the_past))
      Job::Queue.for(job).name.should == 'builds.docker'
    end

    it 'returns the matching queue when language is also given' do
      job = stub('job', config: { language: 'clojure', sudo: false }, repository: stub('travis-core', owner_name: 'travis-ci', name: 'travis-core', owner: stub, :created_at => the_past))
      Job::Queue.for(job).name.should == 'builds.docker'
    end
  end

  describe 'Queue.queues' do
    it 'returns an array of Queues for the config hash' do
      rails, _, docker, _, _, cloudfoundry, clojure, _ = Job::Queue.send(:queues)

      rails.name.should == 'builds.rails'
      rails.attrs[:slug].should == 'rails/rails'

      docker.name.should == 'builds.docker'
      docker.attrs[:sudo].should == false

      cloudfoundry.name.should == 'builds.cloudfoundry'
      cloudfoundry.attrs[:owner].should == 'cloudfoundry'

      clojure.name.should == 'builds.clojure'
      clojure.attrs[:language].should == 'clojure'
    end
  end

  describe 'matches?' do
    it "returns false when neither of slug or language match" do
      queue = queue('builds.linux', {})
      queue.matches?(stub('job', repository: stub('repository', owner_name: 'foo', name: 'bar', owner: nil), config: { language: 'COBOL' })).should be_false
    end

    it "returns true when the given owner matches" do
      queue = queue('builds.cloudfoundry', { owner: 'cloudfoundry' })
      queue.matches?(stub('job', repository: stub('repository', owner_name: 'cloudfoundry', name: 'bosh', owner: nil), config: {})).should be_true
    end

    it "returns true when the given slug matches" do
      queue = queue('builds.rails', { slug: 'rails/rails' })
      queue.matches?(stub('job', repository: stub('repository', owner_name: 'rails', name: 'rails', owner: nil), config: {})).should be_true
    end

    it "returns true when the given language matches" do
      queue = queue('builds.linux', { language: 'clojure' })
      queue.matches?(stub('job', repository: stub('repository', owner_name: nil, name: nil, owner: nil), config: { language: 'clojure' })).should be_true
    end

    it 'returns true when os is missing' do
      queue = queue('builds.linux', { language: 'clojure' })
      queue.matches?(stub('job', repository: stub('repository', owner_name: nil, name: nil, owner: nil), config: { language: 'clojure' })).should be_true
    end

    it 'returns true when sudo is false' do
      queue = queue('builds.docker', { sudo: false })
      queue.matches?(stub('job', repository: stub('repository', owner_name: nil, name: nil, owner: nil), config: { sudo: false })).should be_true
    end

    it 'returns false when sudo is true' do
      queue = queue('builds.docker', { sudo: false })
      queue.matches?(stub('job', repository: stub('repository', owner_name: nil, name: nil, owner: nil), config: { sudo: true })).should be_false
    end

    it 'returns false when sudo is not specified' do
      queue = queue('builds.docker', { sudo: false })
      queue.matches?(stub('job', repository: stub('repository', owner_name: nil, name: nil, owner: nil), config: {})).should be_false
    end

    it 'returns true when dist matches' do
      queue = queue('builds.gce', { dist: 'trusty' })
      queue.matches?(stub('job', repository: stub('repository', owner_name: nil, name: nil, owner: nil), config: { dist: 'trusty' })).should be_true
    end

    it 'returns false when dist does not match' do
      queue = queue('builds.docker', { dist: 'precise' })
      queue.matches?(stub('job', repository: stub('repository', owner_name: nil, name: nil, owner: nil), config: { dist: 'trusty' })).should be_false
    end

    it 'returns true when osx_image matches' do
      queue = queue('builds.mac_beta', { osx_image: 'beta' })
      queue.matches?(stub('job', repository: stub('repository', owner_name: nil, name: nil, owner: nil), config: { osx_image: 'beta' })).should be_true
    end

    it 'returns false when osx_image does not match' do
      queue = queue('builds.mac_stable', { osx_image: 'stable' })
      queue.matches?(stub('job', repository: stub('repository', owner_name: nil, name: nil, owner: nil), config: { osx_image: 'beta' })).should be_false
    end

    it 'returns true when services match' do
      queue = queue('builds.gce', { services: %w(docker) })
      queue.matches?(stub('job', repository: stub('repository', owner_name: nil, name: nil, owner: nil), config: { services: %w(redis docker postgresql) })).should be_true
    end

    it 'returns false when services do not match' do
      queue = queue('builds.gce', { services: %w(docker) })
      queue.matches?(stub('job', repository: stub('repository', owner_name: nil, name: nil, owner: nil), config: { services: %w(redis postgresql) })).should be_false
    end

    it 'returns false if no valid matchers are specified' do
      queue = queue('builds.invalid', { foobar_donotmatch: true })
      queue.matches?(stub('job', repository: stub('repository', owner_name: nil, name: nil, owner: nil), config: {})).should be_false
    end

    it 'returns true for percentage: 100' do
      queue = queue('builds.always', { percentage: 100 })
      queue.matches?(stub('job', repository: stub('repository', owner_name: nil, name: nil, owner: nil), config: {})).should be_true
    end

    it 'returns false for percentage: 0' do
      queue = queue('builds.always', { percentage: 0 })
      queue.matches?(stub('job', repository: stub('repository', owner_name: nil, name: nil, owner: nil), config: {})).should be_false
    end
  end
end

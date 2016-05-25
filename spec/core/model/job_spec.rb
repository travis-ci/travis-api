require 'spec_helper'

describe Job do
  include Support::ActiveRecord

  describe '.result' do
    it 'returns 1 for failed builds' do
      job = Factory.build(:test, state: :failed)
      job.result.should == 1
    end

    it 'returns 0 for passed builds' do
      job = Factory.build(:test, state: :passed)
      job.result.should == 0
    end
  end

  describe ".queued" do
    let(:jobs) { [Factory.create(:test), Factory.create(:test), Factory.create(:test)] }

    it "returns jobs that are created but not started or finished" do
      jobs.first.start!
      jobs.third.start!
      jobs.third.finish!(state: 'passed')

      Job.queued.should include(jobs.second)
      Job.queued.should_not include(jobs.first)
      Job.queued.should_not include(jobs.third)
    end
  end

  describe 'before_create' do
    let(:job) { Job::Test.create!(owner: Factory(:user), repository: Factory(:repository), commit: Factory(:commit), source: Factory(:build)) }

    before :each do
      Job::Test.any_instance.stubs(:enqueueable?).returns(false) # prevent jobs to enqueue themselves on create
    end

    it 'instantiates the log' do
      job.reload.log.should be_instance_of(Log)
    end

    it 'sets the state attribute' do
      job.reload.should be_created
    end

    it 'sets the queue attribute' do
      job.reload.queue.should == 'builds.linux'
    end
  end

  describe 'duration' do
    it 'returns nil if both started_at is not populated' do
      job = Job.new(finished_at: Time.now)
      job.duration.should be_nil
    end

    it 'returns nil if both finished_at is not populated' do
      job = Job.new(started_at: Time.now)
      job.duration.should be_nil
    end

    it 'returns the duration if both started_at and finished_at are populated' do
      job = Job.new(started_at: 20.seconds.ago, finished_at: 10.seconds.ago)
      job.duration.should == 10
    end
  end

  describe 'obfuscated config' do
    it 'handles nil env' do
      job = Job.new(repository: Factory(:repository))
      job.config = { rvm: '1.8.7', env: nil }

      job.obfuscated_config.should == {
        rvm: '1.8.7',
        env: nil
      }
    end

    it 'leaves regular vars untouched' do
      job = Job.new(repository: Factory(:repository))
      job.expects(:secure_env_enabled?).at_least_once.returns(true)
      job.config = { rvm: '1.8.7', env: 'FOO=foo' }

      job.obfuscated_config.should == {
        rvm: '1.8.7',
        env: 'FOO=foo'
      }
    end

    it 'obfuscates env vars' do
      job = Job.new(repository: Factory(:repository))
      job.expects(:secure_env_enabled?).at_least_once.returns(true)
      config = { rvm: '1.8.7',
                 env: [job.repository.key.secure.encrypt('BAR=barbaz'), 'FOO=foo']
               }
      job.config = config

      job.obfuscated_config.should == {
        rvm: '1.8.7',
        env: 'BAR=[secure] FOO=foo'
      }
    end

    it 'normalizes env vars which are hashes to strings' do
      job = Job.new(repository: Factory(:repository))
      job.expects(:secure_env_enabled?).at_least_once.returns(true)

      config = { rvm: '1.8.7',
                 env: [{FOO: 'bar', BAR: 'baz'},
                          job.repository.key.secure.encrypt('BAR=barbaz')]
               }
      job.config = config

      job.obfuscated_config.should == {
        rvm: '1.8.7',
        env: 'FOO=bar BAR=baz BAR=[secure]'
      }
    end

    it 'removes addons config if it is not a hash' do
      job = Job.new(repository: Factory(:repository))
      config = { rvm: '1.8.7',
                 addons: "foo",
               }
      job.config = config

      job.obfuscated_config.should == {
        rvm: '1.8.7'
      }
    end

    it 'removes addons items which are not whitelisted' do
      job = Job.new(repository: Factory(:repository))
      config = { rvm: '1.8.7',
                 addons: { sauce_connect: true, firefox: '22.0' },
               }
      job.config = config

      job.obfuscated_config.should == {
        rvm: '1.8.7',
        addons: {
          firefox: '22.0'
        }
      }
    end

    it 'removes source key' do
      job = Job.new(repository: Factory(:repository))
      config = { rvm: '1.8.7',
                 source_key: '1234'
               }
      job.config = config

      job.obfuscated_config.should == {
        rvm: '1.8.7',
      }
    end

    context 'when job has secure env disabled' do
      let :job do
        job = Job.new(repository: Factory(:repository))
        job.expects(:secure_env_enabled?).returns(false).at_least_once
        job
      end

      it 'removes secure env vars' do
        config = { rvm: '1.8.7',
                   env: [job.repository.key.secure.encrypt('BAR=barbaz'), 'FOO=foo']
                 }
        job.config = config

        job.obfuscated_config.should == {
          rvm: '1.8.7',
          env: 'FOO=foo'
        }
      end

      it 'works even if it removes all env vars' do
        config = { rvm: '1.8.7',
                   env: [job.repository.key.secure.encrypt('BAR=barbaz')]
                 }
        job.config = config

        job.obfuscated_config.should == {
          rvm: '1.8.7',
          env: nil
        }
      end

      it 'normalizes env vars which are hashes to strings' do
        config = { rvm: '1.8.7',
                   env: [{FOO: 'bar', BAR: 'baz'},
                            job.repository.key.secure.encrypt('BAR=barbaz')]
                 }
        job.config = config

        job.obfuscated_config.should == {
          rvm: '1.8.7',
          env: 'FOO=bar BAR=baz'
        }
      end
    end
  end

  describe '#pull_request?' do
    it 'is delegated to commit' do
      commit = Commit.new
      commit.expects(:pull_request?).returns(true)

      job = Job.new
      job.commit = commit
      job.pull_request?.should be_true
    end
  end

  describe 'decrypted config' do
    it 'handles nil env' do
      job = Job.new(repository: Factory(:repository))
      job.config = { rvm: '1.8.7', env: nil, global_env: nil }

      job.decrypted_config.should == {
        rvm: '1.8.7',
        env: nil,
        global_env: nil
      }
    end

    it 'normalizes env vars which are hashes to strings' do
      job = Job.new(repository: Factory(:repository))
      job.expects(:secure_env_enabled?).at_least_once.returns(true)

      config = { rvm: '1.8.7',
                 env: [{FOO: 'bar', BAR: 'baz'},
                          job.repository.key.secure.encrypt('BAR=barbaz')],
                 global_env: [{FOO: 'foo', BAR: 'bar'},
                          job.repository.key.secure.encrypt('BAZ=baz')]
               }
      job.config = config

      job.decrypted_config.should == {
        rvm: '1.8.7',
        env: ["FOO=bar BAR=baz", "SECURE BAR=barbaz"],
        global_env: ["FOO=foo BAR=bar", "SECURE BAZ=baz"]
      }
    end

    it 'does not change original config' do
      job = Job.new(repository: Factory(:repository))
      job.expects(:secure_env_enabled?).at_least_once.returns(true)

      config = {
                 env: [{secure: 'invalid'}],
                 global_env: [{secure: 'invalid'}]
               }
      job.config = config

      job.decrypted_config
      job.config.should == {
        env: [{ secure: 'invalid' }],
        global_env: [{ secure: 'invalid' }]
      }
    end

    it 'leaves regular vars untouched' do
      job = Job.new(repository: Factory(:repository))
      job.expects(:secure_env_enabled?).returns(true).at_least_once
      job.config = { rvm: '1.8.7', env: 'FOO=foo', global_env: 'BAR=bar' }

      job.decrypted_config.should == {
        rvm: '1.8.7',
        env: ['FOO=foo'],
        global_env: ['BAR=bar']
      }
    end

    context 'when secure env is not enabled' do
      let :job do
        job = Job.new(repository: Factory(:repository))
        job.expects(:secure_env_enabled?).returns(false).at_least_once
        job
      end

      it 'removes secure env vars' do
        config = { rvm: '1.8.7',
                   env: [job.repository.key.secure.encrypt('BAR=barbaz'), 'FOO=foo'],
                   global_env: [job.repository.key.secure.encrypt('BAR=barbaz'), 'BAR=bar']
                 }
        job.config = config

        job.decrypted_config.should == {
          rvm: '1.8.7',
          env: ['FOO=foo'],
          global_env: ['BAR=bar']
        }
      end

      it 'removes only secured env vars' do
        config = { rvm: '1.8.7',
                   env: [job.repository.key.secure.encrypt('BAR=barbaz'), 'FOO=foo']
                 }
        job.config = config

        job.decrypted_config.should == {
          rvm: '1.8.7',
          env: ['FOO=foo']
        }
      end
    end

    context 'when addons are disabled' do
      let :job do
        job = Job.new(repository: Factory(:repository))
        job.expects(:addons_enabled?).returns(false).at_least_once
        job
      end

      it 'removes addons if it is not a hash' do
        config = { rvm: '1.8.7',
                   addons: []
                 }
        job.config = config

        job.decrypted_config.should == {
          rvm: '1.8.7'
        }
      end

      it 'removes addons items which are not whitelisted' do
        config = { rvm: '1.8.7',
                   addons: {
                     sauce_connect: {
                       username: 'johndoe',
                       access_key: job.repository.key.secure.encrypt('foobar')
                     },
                     firefox: '22.0',
                     mariadb: '10.1',
                     postgresql: '9.3',
                     hosts: %w(travis.dev),
                     apt_packages: %w(curl git),
                     apt_sources: %w(deadsnakes)
                   }
                 }
        job.config = config

        job.decrypted_config.should == {
          rvm: '1.8.7',
          addons: {
            firefox: '22.0',
            mariadb: '10.1',
            postgresql: '9.3',
            hosts: %w(travis.dev),
            apt_packages: %w(curl git),
            apt_sources: %w(deadsnakes)
          }
        }
      end
    end

    context 'when job has secure env enabled' do
      let :job do
        job = Job.new(repository: Factory(:repository))
        job.expects(:secure_env_enabled?).returns(true).at_least_once
        job
      end

      it 'decrypts env vars' do
        config = { rvm: '1.8.7',
                   env: job.repository.key.secure.encrypt('BAR=barbaz'),
                   global_env: job.repository.key.secure.encrypt('BAR=bazbar')
                 }
        job.config = config

        job.decrypted_config.should == {
          rvm: '1.8.7',
          env: ['SECURE BAR=barbaz'],
          global_env: ['SECURE BAR=bazbar']
        }
      end

      it 'decrypts only secure env vars' do
        config = { rvm: '1.8.7',
                   env: [job.repository.key.secure.encrypt('BAR=bar'), 'FOO=foo'],
                   global_env: [job.repository.key.secure.encrypt('BAZ=baz'), 'QUX=qux']
                 }
        job.config = config

        job.decrypted_config.should == {
          rvm: '1.8.7',
          env: ['SECURE BAR=bar', 'FOO=foo'],
          global_env: ['SECURE BAZ=baz', 'QUX=qux']
        }
      end
    end

    context 'when job has addons enabled' do
      let :job do
        job = Job.new(repository: Factory(:repository))
        job.expects(:addons_enabled?).returns(true).at_least_once
        job
      end

      it 'decrypts addons config' do
        config = { rvm: '1.8.7',
                   addons: {
                     sauce_connect: {
                       username: 'johndoe',
                       access_key: job.repository.key.secure.encrypt('foobar')
                     }
                   }
                 }
        job.config = config

        job.decrypted_config.should == {
          rvm: '1.8.7',
          addons: {
            sauce_connect: {
              username: 'johndoe',
              access_key: 'foobar'
            }
          }
        }
      end

      it 'decrypts deploy addon config' do
        config = { rvm: '1.8.7',
                   deploy: { foo: job.repository.key.secure.encrypt('foobar') }
                 }
        job.config = config

        job.decrypted_config.should == {
          rvm: '1.8.7',
          addons: {
            deploy: { foo: 'foobar' }
          }
        }
      end

      it 'removes addons config if it is an array and deploy is present' do
        config = { rvm: '1.8.7',
                   addons: ["foo"],
                   deploy: { foo: 'bar'}
                 }
        job.config = config

        job.decrypted_config.should == {
          rvm: '1.8.7',
          addons: {
            deploy: { foo: 'bar' }
          }
        }
      end

    end
  end

  describe 'log_content=' do
    let(:job) { Job::Test.create!(owner: Factory(:user), repository: Factory(:repository), commit: Factory(:commit), source: Factory(:build), log: Factory(:log)) }

    it 'sets the log content' do
      job.log_content = 'Hello, world'
      job.log.content.should == 'Hello, world'
    end

    it 'blanks out any old log content' do
      job.log_content = 'foo'
      job.log_content = 'bar'
      job.log.content.should == 'bar'
    end
  end
end

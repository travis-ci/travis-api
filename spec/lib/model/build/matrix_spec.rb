describe Build, 'matrix' do
  describe :matrix_finished? do
    context 'if config[:matrix][:finish_fast] is not set' do
      context 'if at least one job has not finished and is not allowed to fail' do
        it 'returns false' do
          build = FactoryBot.create(:build, config: { rvm: ['1.8.7', '1.9.2'] })
          build.matrix[0].update(state: :passed)
          build.matrix[1].update(state: :started)

          expect(build.matrix_finished?).not_to be true
        end
      end

      context 'if at least one job has not finished and is allowed to fail' do
        it 'returns false' do
          build = FactoryBot.create(:build, config: { rvm: ['1.8.7', '1.9.2'] })
          build.matrix[0].update(state: :passed)
          build.matrix[1].update(state: :started, allow_failure: true)

          expect(build.matrix_finished?).not_to be true
        end
      end

      context 'if all jobs have finished' do
        it 'returns true' do
          build = FactoryBot.create(:build, config: { rvm: ['1.8.7', '1.9.2'] })
          build.matrix[0].update!(state: :passed)
          build.matrix[1].update!(state: :passed)

          expect(build.matrix_finished?).to be true
        end
      end
    end
    context 'if config[:matrix][:finish_fast] is set' do
      context 'if at least one job has not finished and is not allowed to fail' do
        it 'returns false' do
          build = FactoryBot.create(:build, config: { rvm: ['1.8.7', '1.9.2'], matrix: {fast_finish: true} })
          build.matrix[0].update(state: :passed)
          build.matrix[1].update(state: :started)

          expect(build.matrix_finished?).to be false
        end
      end

      context 'if at least one job has not finished and is allowed to fail' do
        it 'returns true' do
          build = FactoryBot.create(:build, config: { rvm: ['1.8.7', '1.9.2'], matrix: {fast_finish: true} })
          build.matrix[0].update(state: :passed)
          build.matrix[1].update(state: :started, allow_failure: true)

          expect(build.matrix_finished?).to be true
        end
      end

      context 'if all jobs have finished' do
        it 'returns true' do
          build = FactoryBot.create(:build, config: { rvm: ['1.8.7', '1.9.2'], matrix: {fast_finish: true} })
          build.matrix[0].update!(state: :passed)
          build.matrix[1].update!(state: :passed)

          expect(build.matrix_finished?).to be true
        end
      end
    end
  end

  describe :matrix_state do
    let(:build) { FactoryBot.create(:build, config: { rvm: ['1.8.7', '1.9.2'] }) }

    it 'returns :passed if all jobs have passed' do
      build.matrix[0].update!(state: "passed")
      build.matrix[1].update!(state: "passed")
      expect(build.matrix_state).to eq(:passed)
    end

    it 'returns :failed if one job has failed' do
      build.matrix[0].update!(state: "passed")
      build.matrix[1].update!(state: "failed")
      expect(build.matrix_state).to eq(:failed)
    end

    it 'returns :failed if one job has failed and one job has errored' do
      build.matrix[0].update!(state: "errored")
      build.matrix[1].update!(state: "failed")
      expect(build.matrix_state).to eq(:errored)
    end

    it 'returns :errored if one job has errored' do
      build.matrix[0].update!(state: "passed")
      build.matrix[1].update!(state: "errored")
      expect(build.matrix_state).to eq(:errored)
    end

    it 'returns :passed if a errored job is allowed to fail' do
      build.matrix[0].update!(state: "passed")
      build.matrix[1].update!(state: "errored", allow_failure: true)
      expect(build.matrix_state).to eq(:passed)
    end

    it 'returns :passed if a failed job is allowed to fail' do
      build.matrix[0].update!(state: "passed")
      build.matrix[1].update!(state: "failed", allow_failure: true)
      expect(build.matrix_state).to eq(:passed)
    end

    it 'returns :failed if all jobs have failed and only one is allowed to fail' do
      build.matrix[0].update!(state: "failed")
      build.matrix[1].update!(state: "failed", allow_failure: true)
      expect(build.matrix_state).to eq(:failed)
    end

    it 'returns :failed if all jobs have failed and only one is allowed to fail' do
      build.matrix[0].update!(state: "finished")
      expect { build.matrix_state }.to raise_error(StandardError)
    end

    it 'returns :passed if all jobs have passed except a job that is allowed to fail, and config[:matrix][:finish_fast] is set' do
      build.config.update(finish_fast: true)
      build.matrix[0].update!(state: "passed")
      build.matrix[1].update!(state: "failed", allow_failure: true)
      expect(build.matrix_state).to eq(:passed)
    end
  end

  context 'matrix with one allow_failure job' do
    let(:build) { FactoryBot.create(:build, config: { rvm: ['1.9.3'] }) }

    it 'returns :passed' do
      build.matrix[0].update!(state: "failed", allow_failure: true)
      expect(build.matrix_state).to eq(:passed)
    end
  end

  describe :matrix_duration do
    let(:build) do
      Build.new(matrix: [
        Job::Test.new(started_at: 60.seconds.ago, finished_at: 40.seconds.ago),
        Job::Test.new(started_at: 20.seconds.ago, finished_at: 10.seconds.ago)
       ])
    end

    context 'if the matrix is finished' do
      it 'returns the sum of the matrix job durations' do
        allow(build).to receive(:matrix_finished?).and_return(true)
        expect(build.matrix_duration).to eq(30)
      end
    end

    context 'if the matrix is not finished' do
      it 'returns nil' do
        allow(build).to receive(:matrix_finished?).and_return(false)
        expect(build.matrix_duration).to be_nil
      end
    end
  end

  describe 'for Ruby projects' do
    let(:no_matrix_config) {
      YAML.load <<-yml
      script: 'rake ci'
    yml
    }

    let(:single_test_config) {
      YAML.load <<-yml
      script: 'rake ci'
      rvm:
        - 1.8.7
      gemfile:
        - gemfiles/rails-3.0.6
      env:
        - USE_GIT_REPOS=true
    yml
    }

    let(:env_global_config) {
      YAML.load <<-yml
      script: 'rake ci'
      rvm:
        - 1.9.2
        - 1.9.3
      gemfile:
        - gemfiles/rails-4.0.0
      env:
        global:
          - TOKEN=abcdef
        matrix:
          - FOO=bar
          - BAR=baz
    yml
    }

    let(:multiple_tests_config) {
      YAML.load <<-yml
      script: 'rake ci'
      rvm:
        - 1.8.7
        - 1.9.1
        - 1.9.2
      gemfile:
        - gemfiles/rails-3.0.6
        - gemfiles/rails-3.0.7
        - gemfiles/rails-3-0-stable
        - gemfiles/rails-master
      env:
        - USE_GIT_REPOS=true
    yml
    }

    let(:multiple_tests_config_with_exculsion) {
      YAML.load <<-yml
      rvm:
        - 1.8.7
        - 1.9.2
      gemfile:
        - gemfiles/rails-2.3.x
        - gemfiles/rails-3.0.x
        - gemfiles/rails-3.1.x
      matrix:
        exclude:
          - rvm: 1.8.7
            gemfile: gemfiles/rails-3.1.x
          - rvm: 1.9.2
            gemfile: gemfiles/rails-2.3.x
    yml
    }

    let(:multiple_tests_config_with_global_env_and_exclusion) {
      YAML.load <<-yml
      rvm:
        - 1.9.2
        - 2.0.0
      gemfile:
        - gemfiles/rails-3.1.x
        - gemfiles/rails-4.0.x
      env:
        global:
          - FOO=bar
      matrix:
        exclude:
          - rvm: 1.9.2
            gemfile: gemfiles/rails-4.0.x
      yml
    }

    let(:multiple_tests_config_with_invalid_exculsion) {
      YAML.load <<-yml
      rvm:
        - 1.8.7
        - 1.9.2
      gemfile:
        - gemfiles/rails-3.0.x
        - gemfiles/rails-3.1.x
      env:
        - FOO=bar
        - BAR=baz
      matrix:
        exclude:
          - rvm: 1.9.2
            gemfile: gemfiles/rails-3.0.x
    yml
    }

    let(:multiple_tests_config_with_inclusion) {
      YAML.load <<-yml
      rvm:
        - 1.8.7
        - 1.9.2
      env:
        - FOO=bar
        - BAR=baz
      matrix:
        include:
          - rvm: 1.9.2
            env: BAR=xyzzy
    yml
    }

    let(:matrix_with_inclusion_only) {
      YAML.load <<-yml
      language: ruby
      matrix:
        include:
          - rvm: "2.1.0"
            env: FOO=true
          - rvm: "2.1.0"
            env: BAR=true
          - rvm: "1.9.3"
            env: BAZ=true
    yml
    }

    let(:matrix_with_empty_include) {
      YAML.load <<-yml
      language: ruby
      matrix:
        include:
    yml
    }

    let(:multiple_tests_config_with_allow_failures) {
      YAML.load <<-yml
      language: objective-c
      rvm:
        - 1.8.7
        - 1.9.2
      xcode_sdk:
        - iphonesimulator6.1
        - iphonesimulator7.0
      matrix:
        allow_failures:
          - rvm: 1.8.7
            xcode_sdk: iphonesimulator7.0
    yml
    }

    let(:allow_failures_with_global_env) {
      YAML.load <<-yml
      rvm:
        - 1.9.3
        - 2.0.0
      env:
        global:
          - "GLOBAL=global NEXT_GLOBAL=next"
        matrix:
          - "FOO=bar"
          - "FOO=baz"
      matrix:
        allow_failures:
          - rvm: 1.9.3
            env: "FOO=bar"
    yml
    }

    let(:scalar_allow_failures) {
      YAML.load <<-yml
      env:
        global:
          - "GLOBAL=global NEXT_GLOBAL=next"
        matrix:
          - "FOO=bar"
          - "FOO=baz"
      matrix:
        allow_failures:
          "FOO=bar"
    yml
    }

    let(:matrix_with_unwanted_expansion_ruby) {
      YAML.load <<-yml
      language: ruby
      python:
        - 3.3
        - 2.7
      rvm:
        - 2.0.0
        - 1.9.3
      gemfile:
        - 'gemfiles/rails-4'
    yml
    }

    let(:matrix_with_unwanted_expansion_python) {
      YAML.load <<-yml
      language: python
      python:
        - "3.3"
        - "2.7"
      rvm:
        - 2.0.0
        - 1.9.3
      gemfile:
        - 'gemfiles/rails-4'
    yml
    }

    let(:ruby_matrix_with_incorrect_allow_failures) {
      YAML.load <<-yml
      language: ruby

      rvm:
        - "1.9.3"
        - "2.1.0"

      matrix:
        fast_finish: true
        allow_failures:
          - what: "ever"
    yml
    }

    describe :expand_matrix do
      it 'does not expand on :os' do
        build = FactoryBot.create(:build, config: { rvm: ['1.9.3', '2.0.0'], os: ['osx', 'linux']})
        expect(build.matrix.map(&:config)).to eq([
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.3' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '2.0.0' }
        ])
      end

      it 'does not clobber env and global_env vars' do
        build = FactoryBot.create(:build, config: env_global_config)

        expect(build.matrix.map(&:config)).to eq([
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci', rvm: '1.9.2', gemfile: 'gemfiles/rails-4.0.0', env: 'FOO=bar', global_env: ['TOKEN=abcdef'] },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci', rvm: '1.9.2', gemfile: 'gemfiles/rails-4.0.0', env: 'BAR=baz', global_env: ['TOKEN=abcdef'] },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci', rvm: '1.9.3', gemfile: 'gemfiles/rails-4.0.0', env: 'FOO=bar', global_env: ['TOKEN=abcdef'] },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci', rvm: '1.9.3', gemfile: 'gemfiles/rails-4.0.0', env: 'BAR=baz', global_env: ['TOKEN=abcdef'] }
        ])
      end

      it 'sets the config to the jobs (no config)' do
        build = FactoryBot.create(:build, config: {})
        expect(build.matrix.map(&:config)).to eq([
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise' }
        ])
      end

      it 'sets the config to the jobs (no matrix config)' do
        build = FactoryBot.create(:build, config: no_matrix_config)
        expect(build.matrix.map(&:config)).to eq([
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci' }
        ])
      end

      it 'sets the config to the jobs (single test config)' do
        build = FactoryBot.create(:build, config: single_test_config)
        expect(build.matrix.map(&:config)).to eq([
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci', rvm: '1.8.7', gemfile: 'gemfiles/rails-3.0.6', env: 'USE_GIT_REPOS=true' }
        ])
      end

      it 'sets the config to the jobs (multiple tests config)' do
        build = FactoryBot.create(:build, config: multiple_tests_config)
        expect(build.matrix.map(&:config)).to eq([
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci', rvm: '1.8.7', gemfile: 'gemfiles/rails-3.0.6',      env: 'USE_GIT_REPOS=true' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci', rvm: '1.8.7', gemfile: 'gemfiles/rails-3.0.7',      env: 'USE_GIT_REPOS=true' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci', rvm: '1.8.7', gemfile: 'gemfiles/rails-3-0-stable', env: 'USE_GIT_REPOS=true' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci', rvm: '1.8.7', gemfile: 'gemfiles/rails-master',     env: 'USE_GIT_REPOS=true' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci', rvm: '1.9.1', gemfile: 'gemfiles/rails-3.0.6',      env: 'USE_GIT_REPOS=true' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci', rvm: '1.9.1', gemfile: 'gemfiles/rails-3.0.7',      env: 'USE_GIT_REPOS=true' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci', rvm: '1.9.1', gemfile: 'gemfiles/rails-3-0-stable', env: 'USE_GIT_REPOS=true' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci', rvm: '1.9.1', gemfile: 'gemfiles/rails-master',     env: 'USE_GIT_REPOS=true' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci', rvm: '1.9.2', gemfile: 'gemfiles/rails-3.0.6',      env: 'USE_GIT_REPOS=true' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci', rvm: '1.9.2', gemfile: 'gemfiles/rails-3.0.7',      env: 'USE_GIT_REPOS=true' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci', rvm: '1.9.2', gemfile: 'gemfiles/rails-3-0-stable', env: 'USE_GIT_REPOS=true' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', script: 'rake ci', rvm: '1.9.2', gemfile: 'gemfiles/rails-master',     env: 'USE_GIT_REPOS=true' }
        ])
      end

      it 'sets the config to the jobs (allow failures config)' do
        build = FactoryBot.create(:build, config: multiple_tests_config_with_allow_failures)
        expect(build.matrix.map(&:allow_failure)).to eq([false, true, false, false])
      end

      it 'ignores global env config when setting allow failures' do
        build = FactoryBot.create(:build, config: allow_failures_with_global_env)
        expect(build.matrix.map(&:allow_failure)).to eq([true, false, false, false])
      end

      context 'when matrix specifies incorrect allow_failures' do
        before :each do
          @build = FactoryBot.create(:build, config: ruby_matrix_with_incorrect_allow_failures)
        end

        it 'excludes matrices correctly' do
          expect(@build.matrix.map(&:allow_failure)).to eq([false, false])
        end
      end

      context 'when matrix specifies scalar allow_failures' do
        before :each do
          @build = FactoryBot.create(:build, config: scalar_allow_failures)
        end

        it 'ignores allow_failures silently' do
          expect(@build.matrix.map(&:allow_failure)).to eq([false, false])
        end
      end

      context 'when ruby project contains unwanted key' do
        before :each do
          @build_ruby = FactoryBot.create(:build, config: matrix_with_unwanted_expansion_ruby)
        end

        it 'ignores irrelevant matrix dimensions' do
          expect(@build_ruby.matrix.map(&:config)).to eq([
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '2.0.0', gemfile: 'gemfiles/rails-4' },
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.3', gemfile: 'gemfiles/rails-4' }
          ])
        end

        it 'creates jobs whose config does not contain unwanted keys' do
          configs = @build_ruby.matrix.map { |job| job.config[:python] }.flatten.compact
          expect(configs).to be_empty
        end

        # it 'does not touch config' do
        #   @build_ruby.config.keys.should include(:python)
        # end
      end

      context 'when python project contains unwanted key' do
        before :each do
          @build_python = FactoryBot.create(:build, config: matrix_with_unwanted_expansion_python)
        end

        it 'ignores irrelevant matrix dimensions' do
          expect(@build_python.matrix.map(&:config)).to eq([
            { os: 'linux', language: 'python', group: 'stable', dist: 'precise', python: '3.3' },
            { os: 'linux', language: 'python', group: 'stable', dist: 'precise', python: '2.7' }
          ])
        end

        # it 'does not touch config' do
        #   @build_python.config.keys.should include(:rvm)
        # end
      end

      it 'copies build attributes' do
        # TODO spec other attributes!
        build = FactoryBot.create(:build, config: multiple_tests_config)
        expect(build.matrix.map(&:commit_id).uniq).to eq([build.commit_id])
      end

      it 'adds a sub-build number to the job number' do
        build = FactoryBot.create(:build, config: multiple_tests_config)
        numbers = build.matrix.map(&:number)[0..3].map { |num| num.split('.').last }
        expect(numbers).to eq(['1', '2', '3', '4'])
      end

      describe :exclude_matrix_config do
        it 'excludes a matrix config when all config items are defined in the exclusion' do
          build = FactoryBot.create(:build, config: multiple_tests_config_with_exculsion)
          matrix_exclusion = {
            exclude: [
              { rvm: '1.8.7', gemfile: 'gemfiles/rails-3.1.x' },
              { rvm: '1.9.2', gemfile: 'gemfiles/rails-2.3.x' }
            ]
          }

          expect(build.matrix.map(&:config)).to eq([
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.8.7', gemfile: 'gemfiles/rails-2.3.x' },
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.8.7', gemfile: 'gemfiles/rails-3.0.x' },
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.2', gemfile: 'gemfiles/rails-3.0.x' },
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.2', gemfile: 'gemfiles/rails-3.1.x' }
          ])
        end

        it "excludes a matrix config without specifying global env vars in the exclusion" do
          build = FactoryBot.create(:build, config: multiple_tests_config_with_global_env_and_exclusion)
          matrix_exclusion = { exclude: [{ rvm: "1.9.2", gemfile: "gemfiles/rails-4.0.x" }] }

          expect(build.matrix.map(&:config)).to eq([
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: "1.9.2", gemfile: "gemfiles/rails-3.1.x", global_env: ["FOO=bar"] },
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: "2.0.0", gemfile: "gemfiles/rails-3.1.x", global_env: ["FOO=bar"] },
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: "2.0.0", gemfile: "gemfiles/rails-4.0.x", global_env: ["FOO=bar"] },
          ])
        end

        it 'excludes jobs from a matrix config when the matrix exclusion definition is incomplete' do
          build = FactoryBot.create(:build, config: multiple_tests_config_with_invalid_exculsion)

          matrix_exclusion = { exclude: [{ rvm: '1.9.2', gemfile: 'gemfiles/rails-3.0.x' }] }

          expect(build.matrix.map(&:config)).to eq([
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.8.7', gemfile: 'gemfiles/rails-3.0.x', env: 'FOO=bar' },
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.8.7', gemfile: 'gemfiles/rails-3.0.x', env: 'BAR=baz' },
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.8.7', gemfile: 'gemfiles/rails-3.1.x', env: 'FOO=bar' },
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.8.7', gemfile: 'gemfiles/rails-3.1.x', env: 'BAR=baz' },
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.2', gemfile: 'gemfiles/rails-3.1.x', env: 'FOO=bar' },
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.2', gemfile: 'gemfiles/rails-3.1.x', env: 'BAR=baz' }
          ])
        end
      end
    end

    describe :include_matrix_config do
      it 'includes a matrix config' do
          build = FactoryBot.create(:build, config: multiple_tests_config_with_inclusion)

          matrix_inclusion = {
            include: [
              { rvm: '1.9.2', env: 'BAR=xyzzy' }
            ]
          }

          expect(build.matrix.map(&:config)).to eq([
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.8.7', env: 'FOO=bar' },
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.8.7', env: 'BAR=baz' },
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.2', env: 'FOO=bar' },
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.2', env: 'BAR=baz' },
            { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.2', env: 'BAR=xyzzy' }
          ])
        end

      it 'does not include "empty" matrix config' do
        build = FactoryBot.create(:build, config: matrix_with_inclusion_only)

        matrix_inclusion = {
          include: [
            { rvm: '2.1.0', env: 'FOO=true' },
            { rvm: '2.1.0', env: 'BAR=true' },
            { rvm: '1.9.3', env: 'BAZ=true' }
          ]
        }

        expect(build.matrix.map(&:config)).to eq([
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '2.1.0', env: 'FOO=true' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '2.1.0', env: 'BAR=true' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.3', env: 'BAZ=true' }
        ])
      end

      it 'includes "empty" matrix config when matrix.include is null' do
        build = FactoryBot.create(:build, config: matrix_with_empty_include)

        matrix_inclusion = {
          include: nil
        }

        expect(build.matrix.map(&:config)).to eq([])
      end
    end

    describe 'matrix expansion' do
      let(:repository) { FactoryBot.create(:repository) }

      it 'with string values' do
        build = FactoryBot.create(:build, config: { rvm: '1.8.7', gemfile: 'gemfiles/rails-2.3.x', env: 'FOO=bar' })
        expect(build.matrix.map(&:config)).to eq([
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.8.7', gemfile: 'gemfiles/rails-2.3.x', env: 'FOO=bar' }
        ])
      end

      it 'does not decrypt secure env vars' do
        repository.regenerate_key!
        env = repository.key.secure.encrypt('FOO=bar').symbolize_keys
        config = { rvm: '1.8.7', gemfile: 'gemfiles/rails-2.3.x', env: env }
        build = FactoryBot.create(:build, repository: repository, config: config)
        expect(build.matrix.map(&:config)).to eq([
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.8.7', gemfile: 'gemfiles/rails-2.3.x', env: env }
        ])
      end

      it 'with two Rubies and Gemfiles' do
        build = FactoryBot.create(:build, config: { rvm: ['1.8.7', '1.9.2'], gemfile: ['gemfiles/rails-2.3.x', 'gemfiles/rails-3.0.x'] })
        expect(build.matrix.map(&:config)).to eq([
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.8.7', gemfile: 'gemfiles/rails-2.3.x' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.8.7', gemfile: 'gemfiles/rails-3.0.x' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.2', gemfile: 'gemfiles/rails-2.3.x' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.2', gemfile: 'gemfiles/rails-3.0.x' }
        ])
      end

      it 'with unequal number of Rubies, env variables and Gemfiles' do
        build = FactoryBot.create(:build, config: { rvm: ['1.8.7', '1.9.2', 'ree'], gemfile: ['gemfiles/rails-3.0.x'], env: ['DB=postgresql', 'DB=mysql'] })
        expect(build.matrix.map(&:config)).to eq([
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.8.7', gemfile: 'gemfiles/rails-3.0.x', env: 'DB=postgresql' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.8.7', gemfile: 'gemfiles/rails-3.0.x', env: 'DB=mysql' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.2', gemfile: 'gemfiles/rails-3.0.x', env: 'DB=postgresql' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.2', gemfile: 'gemfiles/rails-3.0.x', env: 'DB=mysql' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: 'ree',   gemfile: 'gemfiles/rails-3.0.x', env: 'DB=postgresql' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: 'ree',   gemfile: 'gemfiles/rails-3.0.x', env: 'DB=mysql' },
        ])
      end

      it 'with an array of Rubies and a single Gemfile' do
        build = FactoryBot.create(:build, config: { rvm: ['1.8.7', '1.9.2'], gemfile: 'gemfiles/rails-2.3.x' })
        expect(build.matrix.map(&:config)).to eq([
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.8.7', gemfile: 'gemfiles/rails-2.3.x' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.2', gemfile: 'gemfiles/rails-2.3.x' }
        ])
      end
    end
  end

  describe 'for Scala projects' do
    it 'with a single Scala version given as a string' do
      build = FactoryBot.create(:build, config: { language: 'scala', scala: '2.8.2', env: 'NETWORK=false' })
        expect(build.matrix.map(&:config)).to eq([
        { os: 'linux', language: 'scala', group: 'stable', dist: 'precise', scala: '2.8.2', env: 'NETWORK=false' }
      ])
    end

    it 'with multiple Scala versions and no env variables' do
      build = FactoryBot.create(:build, config: { language: 'scala', scala: ['2.8.2', '2.9.1']})
        expect(build.matrix.map(&:config)).to eq([
        { os: 'linux', language: 'scala', group: 'stable', dist: 'precise', scala: '2.8.2' },
        { os: 'linux', language: 'scala', group: 'stable', dist: 'precise', scala: '2.9.1' }
       ])
    end

    it 'with a single Scala version passed in as array and two env variables' do
      build = FactoryBot.create(:build, config: { language: 'scala', scala: ['2.8.2'], env: ['STORE=postgresql', 'STORE=redis'] })
        expect(build.matrix.map(&:config)).to eq([
        { os: 'linux', language: 'scala', group: 'stable', dist: 'precise', scala: '2.8.2', env: 'STORE=postgresql' },
        { os: 'linux', language: 'scala', group: 'stable', dist: 'precise', scala: '2.8.2', env: 'STORE=redis' }
      ])
    end
  end

  describe 'multi_os' do
    let(:matrix_with_os_ruby) {
      YAML.load(%(
        language: ruby
        os:
          - osx
          - linux
        rvm:
          - 2.0.0
          - 1.9.3
        gemfile:
          - 'gemfiles/rails-4'
      )).deep_symbolize_keys
    }

    let(:repository) { FactoryBot.create(:repository)}
    let(:test) { FactoryBot.create(:test, repository: repository) }

    context 'the feature is active' do
      it 'expands on :os' do
        allow(repository).to receive(:multi_os_enabled?).and_return(true)
        build = FactoryBot.create(:build, config: matrix_with_os_ruby, repository: repository)

        expect(build.matrix.map(&:config)).to eq([
          { os: 'osx', language: 'ruby', group: 'stable', dist: 'precise', rvm: '2.0.0', gemfile: 'gemfiles/rails-4' },
          { os: 'osx', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.3', gemfile: 'gemfiles/rails-4' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '2.0.0', gemfile: 'gemfiles/rails-4' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.3', gemfile: 'gemfiles/rails-4' },
        ])
      end
    end

    context 'the feature is inactive' do
      it 'does not expand on :os' do
        allow(repository).to receive(:multi_os_enabled?).and_return(false)
        build = FactoryBot.create(:build, config: matrix_with_os_ruby, repository: repository)

        expect(build.matrix.map(&:config)).to eq([
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '2.0.0', gemfile: 'gemfiles/rails-4' },
          { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', rvm: '1.9.3', gemfile: 'gemfiles/rails-4' }
        ])
      end
    end
  end

  describe 'os expansion' do
    let(:matrix_with_includes_os_ruby) {
      YAML.load(%(
        language: ruby
        matrix:
          include:
            - os: linux
              compiler: gcc
            - os: linux
              compiler: clang
            - os: osx
              compiler: gcc
            - os: osx
              compiler: clang
      )).deep_symbolize_keys
    }
    let(:repository) { FactoryBot.create(:repository) }
    let(:build)      { FactoryBot.create(:build, repository: repository, config: matrix_with_includes_os_ruby) }

    it 'expands on :os if the feature is active' do
      allow(repository).to receive(:multi_os_enabled?).and_return(true)
      expect(build.matrix.map(&:config)).to eq([
        { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', compiler: 'gcc' },
        { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', compiler: 'clang' },
        { os: 'osx',   language: 'ruby', group: 'stable', dist: 'precise', compiler: 'gcc' },
        { os: 'osx',   language: 'ruby', group: 'stable', dist: 'precise', compiler: 'clang' }
      ])
    end

    it 'ignores the os key if the feature is inactive' do
      allow(repository).to receive(:multi_os_enabled?).and_return(false)
      expect(build.matrix.map(&:config)).to eq([
        { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', compiler: 'gcc' },
        { os: 'linux', language: 'ruby', group: 'stable', dist: 'precise', compiler: 'clang' }
      ])
    end
  end

  describe 'dist_group_expansion' do
    let(:matrix_with_dist_and_group_ruby) {
      YAML.load(%(
        language: ruby
        dist:
          - precise
          - trusty
        group:
          - current
          - update
        rvm:
          - 2.0.0
          - 1.9.3
        gemfile:
          - 'gemfiles/rails-4'
      )).deep_symbolize_keys
    }
    let(:repository) { FactoryBot.create(:repository) }

    context 'the feature is active' do
      it 'expands on :dist and :group' do
        allow(repository).to receive(:dist_group_expansion_enabled?).and_return(true)
        build = FactoryBot.create(:build, repository: repository, config: matrix_with_dist_and_group_ruby)

        expect(build.matrix.map(&:config)).to eq([
          { os: 'linux', language: 'ruby', dist: 'precise', group: 'current', rvm: '2.0.0', gemfile: 'gemfiles/rails-4' },
          { os: 'linux', language: 'ruby', dist: 'precise', group: 'current', rvm: '1.9.3', gemfile: 'gemfiles/rails-4' },
          { os: 'linux', language: 'ruby', dist: 'precise', group: 'update',  rvm: '2.0.0', gemfile: 'gemfiles/rails-4' },
          { os: 'linux', language: 'ruby', dist: 'precise', group: 'update',  rvm: '1.9.3', gemfile: 'gemfiles/rails-4' },
          { os: 'linux', language: 'ruby', dist: 'trusty',  group: 'current', rvm: '2.0.0', gemfile: 'gemfiles/rails-4' },
          { os: 'linux', language: 'ruby', dist: 'trusty',  group: 'current', rvm: '1.9.3', gemfile: 'gemfiles/rails-4' },
          { os: 'linux', language: 'ruby', dist: 'trusty',  group: 'update',  rvm: '2.0.0', gemfile: 'gemfiles/rails-4' },
          { os: 'linux', language: 'ruby', dist: 'trusty',  group: 'update',  rvm: '1.9.3', gemfile: 'gemfiles/rails-4' },
        ])
      end
    end

    context 'the feature is inactive' do
      it 'does not expand on :dist or :group' do
        allow_any_instance_of(Build).to receive(:dist_group_expansion_enabled?).and_return(false)
        build = FactoryBot.create(:build, config: matrix_with_dist_and_group_ruby)

        expect(build.matrix.map(&:config)).to eq([
          { os: 'linux', language: 'ruby', dist: ['precise', 'trusty'], group: ['current', 'update'], rvm: '2.0.0', gemfile: 'gemfiles/rails-4' },
          { os: 'linux', language: 'ruby', dist: ['precise', 'trusty'], group: ['current', 'update'], rvm: '1.9.3', gemfile: 'gemfiles/rails-4' }
        ])
      end
    end
  end

  describe 'filter_matrix' do
    it 'selects matching builds' do
      build = FactoryBot.create(:build, config: { rvm: ['1.8.7', '1.9.2'], env: ['DB=sqlite3', 'DB=postgresql'] })
      expect(build.filter_matrix({ rvm: '1.8.7', env: 'DB=sqlite3' })).to eq([build.matrix[0]])
    end

    it 'does not select builds with non-matching values' do
      build = FactoryBot.create(:build, config: { rvm: ['1.8.7', '1.9.2'], env: ['DB=sqlite3', 'DB=postgresql'] })
      expect(build.filter_matrix({ rvm: 'nomatch', env: 'DB=sqlite3' })).to be_empty
    end

    it 'does not select builds with non-matching keys' do
      build = FactoryBot.create(:build, config: { rvm: ['1.8.7', '1.9.2'], env: ['DB=sqlite3', 'DB=postgresql'] })
      expect(build.filter_matrix({ rvm: '1.8.7', nomatch: 'DB=sqlite3' })).to eq([build.matrix[0], build.matrix[1]])
    end
  end

  describe 'does not explode' do
    it 'on a config key that is `true`' do
      config = { true => 'broken' }
      build = FactoryBot.create(:build, config: config, repository: FactoryBot.create(:repository))
      expect { build.expand_matrix }.to_not raise_error
    end

    it 'on bad matrix include values' do
      config = { matrix: { include: ['broken'] } }
      build = FactoryBot.create(:build, config: config, repository: FactoryBot.create(:repository))
      expect { build.expand_matrix }.to_not raise_error
    end

    it 'on config[:matrix] being an array' do
      config = { matrix: [{ foo: 'kaputt' }] }
      build = FactoryBot.create(:build, config: config, repository: FactoryBot.create(:repository))
      expect { build.expand_matrix }.to_not raise_error
    end
  end


  # describe 'matrix_keys_for' do
  #   let(:config_default_lang) { { 'rvm' => ['1.8.7', '1.9.2'], 'env' => ['DB=sqlite3', 'DB=postgresql'] } }
  #   let(:config_non_def_lang) { { 'language' => 'scala', 'rvm' => ['1.8.7', '1.9.2'], 'env' => ['DB=sqlite3', 'DB=postgresql'] } }
  #   let(:config_lang_array)   { { 'language' => ['scala'], 'rvm' => ['1.8.7', '1.9.2'], 'env' => ['DB=sqlite3', 'DB=postgresql'] } }
  #   let(:config_unrecognized) { { 'language' => 'bash', 'rvm' => ['1.8.7', '1.9.2'], 'env' => ['DB=sqlite3', 'DB=postgresql'] } }

  #   it 'only selects appropriate keys' do
  #     Build.matrix_keys_for(config_default_lang).should == [:rvm, :env]
  #     Build.matrix_keys_for(config_non_def_lang).should == [:env]
  #     Build.matrix_keys_for(config_lang_array).should   == [:env]
  #     Build.matrix_keys_for(config_unrecognized).should == [:rvm, :env]
  #   end
  # end
end

require 'active_support/core_ext/numeric/time'

module Travis
  module Testing
    module Stubs
      require 'travis/testing/stubs/stub'

      class << self
        include Stub

        def included(base)
          base.send(:instance_eval) do
            let(:repository)          { stub_repo                }
            let(:repo)                { stub_repo                }
            let(:request)             { stub_request             }
            let(:commit)              { stub_commit              }
            let(:build)               { stub_build               }
            let(:test)                { stub_test                }
            let(:log)                 { stub_log                 }
            let(:event)               { stub_event               }
            let(:worker)              { stub_worker              }
            let(:user)                { stub_user                }
            let(:org)                 { stub_org                 }
            let(:url)                 { stub_url                 }
            let(:broadcast)           { stub_broadcast           }
            let(:travis_token)        { stub_travis_token        }
            let(:cache)               { stub_cache               }
          end
        end
      end

      def stub_repo(attributes = {})
        Stubs.stub 'repository', attributes.reverse_merge(
          id: 1,
          owner: stub_user(id: 1, login: 'svenfuchs'),
          owner_type: 'User',
          owner_id: 1,
          owner_name: 'svenfuchs',
          owner_email: 'svenfuchs@artweb-design.de',
          name: 'minimal',
          slug: 'svenfuchs/minimal',
          description: 'the repo description',
          url: 'http://github.com/svenfuchs/minimal',
          source_url: 'git://github.com/svenfuchs/minimal.git',
          api_url: 'https://api.github.com/repos/svenfuchs/minimal',
          key: stub_key,
          admin: stub_user,
          active: true,
          private: false,
          private?: false,
          last_build_id: 1,
          last_build_number: 2,
          last_build_started_at: Time.now.utc - 60,
          last_build_finished_at: Time.now.utc,
          last_build_state: :passed,
          last_build_duration: 60,
          github_language: 'ruby',
          github_id: 549743,
          builds_only_with_travis_yml?: false,
          settings: stub_settings,
          users_with_permission: [],
          default_branch: 'master',
          current_build_id: nil
        )
      end
      alias stub_repository stub_repo

      def stub_settings
        Stubs.stub 'settings', 'ssh_keys' => [], 'env_vars' => []
      end

      def stub_key(attributes = {})
        Stubs.stub 'key', attributes.reverse_merge(
          id: 1,
          public_key: '-----BEGIN PUBLIC KEY-----'
        )
      end

      def stub_request(attributes = {})
        repo = stub_repository
        commit = stub_commit
        Stubs.stub 'request', attributes.reverse_merge(
          id: 1,
          repository: repo,
          repository_id: repo.id,
          commit: commit,
          commit_id: commit.id,
          config: {},
          event_type: 'push',
          head_commit: 'head-commit',
          base_commit: 'base-commit',
          token: 'token',
          api_request?: false,
          pull_request?: false,
          comments_url: 'http://github.com/path/to/comments',
          config_url: 'https://api.github.com/repos/svenfuchs/minimal/contents/.travis.yml?ref=62aae5f70ceee39123ef',
          result: :accepted,
          created_at: DateTime.new(2013, 01, 01, 0, 0, 0),
          owner_type: 'User',
          owner_id: 1,
          owner_name: 'svenfuchs',
          owner_email: 'svenfuchs@artweb-design.de',
          message: 'a message',
          branch_name: 'master',
          tag_name: '',
          pull_request: false,
          pull_request_title: nil,
          pull_request_number: nil,
          head_repo: 'BanzaiMan/travis-core',
          head_branch: 'feature-branch',
          base_repo: 'travis-ci/travis-core',
          base_branch: 'master',
        )
      end

      def stub_commit(attributes = {})
        Stubs.stub 'commit', attributes.reverse_merge(
          id: 1,
          commit: '62aae5f70ceee39123ef',
          range: '0cd9ffaab2c4ffee...62aae5f70ceee39123ef',
          branch: 'master',
          ref: 'refs/master',
          tag_name: nil,
          message: 'the commit message',
          author_name: 'Sven Fuchs',
          author_email: 'svenfuchs@artweb-design.de',
          committer_name: 'Sven Fuchs',
          committer_email: 'svenfuchs@artweb-design.de',
          committed_at: Time.now.utc - 3600,
          compare_url: 'https://github.com/svenfuchs/minimal/compare/master...develop',
          pull_request?: false,
          pull_request_number: nil
        )
      end

      def stub_build(attributes = {})
        Stubs.stub 'build', attributes.reverse_merge(
          id: 1,
          repository_id: repository.id,
          repository: stub_repository(owner: attributes.delete(:owner)),
          request_id: request.id,
          request: request,
          commit_id: commit.id,
          commit: commit,
          matrix: attributes[:matrix] || [stub_test(id: 1, number: '2.1'), stub_test(id: 2, number: '2.2')],
          matrix_ids: [1, 2],
          cached_matrix_ids: [1, 2],
          number: 2,
          config: { 'rvm' => ['1.8.7', '1.9.2'], 'gemfile' => ['test/Gemfile.rails-2.3.x', 'test/Gemfile.rails-3.0.x'] },
          obfuscated_config: { 'rvm' => ['1.8.7', '1.9.2'], 'gemfile' => ['test/Gemfile.rails-2.3.x', 'test/Gemfile.rails-3.0.x'] },
          state: 'passed',
          result: 0, # see build/compat.rb
          passed?: true,
          failed?: false,
          finished?: true,
          previous_state: 'passed',
          started_at: Time.now.utc - 60,
          finished_at: Time.now.utc,
          duration: 60,
          pull_request?: false,
          queue: 'builds.linux',
          pull_request_title: nil,
          pull_request_number: nil,
          secure_env_enabled?: true,
          event_type: 'push'
        )
      end

      def stub_test(attributes = {})
        log = self.log
        test = Stubs.stub 'test', attributes.reverse_merge(
          id: 1,
          owner: stub_user,
          owner_type: 'User',
          repository_id: 1,
          repository: repository,
          source_id: 1,
          source_type: 'Build',
          stage_id: 1,
          request_id: 1,
          commit_id: commit.id,
          commit: commit,
          log: log,
          log_id: log.id,
          number: '2.1',
          config: { 'rvm' => '1.8.7', 'gemfile' => 'test/Gemfile.rails-2.3.x' },
          decrypted_config: { 'rvm' => '1.8.7', 'gemfile' => 'test/Gemfile.rails-2.3.x' },
          obfuscated_config: { 'rvm' => '1.8.7', 'gemfile' => 'test/Gemfile.rails-2.3.x' },
          state: :passed,
          result: 0, # see job/compat.rb
          started?: true,
          finished?: true,
          queue: 'builds.linux',
          allow_failure: false,
          started_at: Time.now.utc - 60,
          finished_at: Time.now.utc,
          worker: 'ruby3.worker.travis-ci.org:travis-ruby-4',
          tags: 'tag-a,tag-b',
          log_content: log.content,
          ssh_key: nil,
          secure_env_enabled?: true
        )

        source = stub_build(:matrix => [test])
        test.define_singleton_method(:source) { source }
        test
      end

      def stub_log(attributes = {})
        Stubs.stub 'log', attributes.reverse_merge(
          class: Stubs.stub('class', name: 'Travis::RemoteLog'),
          id: 1,
          job_id: 1,
          content: 'the test log'
        )
      end

      def stub_log_part(attributes = {})
        Stubs.stub 'log_part', attributes.reverse_merge(
          id: 1,
          log_id: 1,
          content: 'the test log',
          number: 1,
          final: false
        )
      end

      def stub_event(attributes = {})
        Stubs.stub 'event', attributes.reverse_merge(
          id: 1,
          repository_id: 1,
          source: stub_request,
          source_id: stub_request.id,
          source_type: 'Request',
          event: 'request:finished',
          data: { 'result' => 'accepted' },
          created_at: Time.now
        )
      end

      def stub_worker(attributes = {})
        Stubs.stub 'worker', attributes.reverse_merge(
          id: 1,
          name: 'ruby-1',
          host: 'ruby-1.worker.travis-ci.org',
          queue: 'builds.linux',
          state: 'created',
          last_seen_at: Time.now.utc,
          payload: nil,
        )
      end

      def stub_user(attributes = {})
        Stubs.stub 'user', attributes.reverse_merge(
          id: 1,
          github_id: 1,
          organizations: [org],
          name: 'Sven Fuchs',
          login: 'svenfuchs',
          email: 'svenfuchs@artweb-design.de',
          gravatar_id: '402602a60e500e85f2f5dc1ff3648ecb',
          avatar_url: 'https://0.gravatar.com/avatar/402602a60e500e85f2f5dc1ff3648ecb',
          locale: 'de',
          github_oauth_token: 'token',
          syncing?: false,
          is_syncing: false,
          synced_at: Time.now.utc - 3600,
          tokens: [double('token', token: 'token')],
          github_scopes: Travis.config.oauth2.scopes.to_s.split(','),
          created_at: Time.now.utc - 7200,
          first_logged_in_at: Time.now.utc - 5400,
          subscribed?: false,
          education: false,
          github?: true,
          vcs_type: 'GithubUser'
        )
      end

      def stub_org(attributes = {})
        Stubs.stub 'org', attributes.reverse_merge(
          id: 1,
          login: 'travis-ci',
          name: 'Travis CI',
          email: 'contact@travis-ci.org',
          subscribed?: false,
          education: false
        )
      end

      def stub_url(attributes = {})
        Stubs.stub 'url', attributes.reverse_merge(
          id: 1,
          short_url: 'http://trvs.io/short'
        )
      end

      def stub_broadcast(attributes = {})
        Stubs.stub 'broadcast', attributes.reverse_merge(
          id: 1,
          message: 'message'
        )
      end

      def stub_travis_token(attributes = {})
        Stubs.stub 'travis_token', attributes.reverse_merge(
          id: 1,
          user: stub_user,
          token: 'super secret'
        )
      end

      def stub_cache(attributes = {})
        Stubs.stub 'cache', attributes.reverse_merge(
          repository: stub_repository,
          size: 1000,
          slug: 'cache',
          branch: 'master',
          last_modified: Time.at(0).utc
        )
      end

      def stub_email(attributes = {})
        Stubs.stub 'email', attributes.reverse_merge(
          email: 'email'
        )
      end

      def stub_job(attributes = {})
        Stubs.stub 'job', attributes.reverse_merge(
          repository: stub_repository,
          owner_type: 'User',
          source_type: 'Build',
          id: '42.1',
          enqueue: true
        )
      end
    end
  end
end

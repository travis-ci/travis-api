require 'json'

class Travis::Api::App::Endpoint
  module Resources
    module Helpers
      def self.json(key)
        JSON.pretty_generate(Resources.const_get(key.to_s.upcase))
      end
    end

    REPOSITORY_KEY = {
      'public_key' => '-----BEGIN RSA PUBLIC KEY-----\nMIGJAoGBAOcx131amMqIzm5+FbZz+DhIgSDbFzjKKpzaN5UWVCrLSc57z64xxTV6\nkaOTZmjCWz6WpaPkFZY+czfL7lmuZ/Y6UNm0vupvdZ6t27SytFFGd1/RJlAe89tu\nGcIrC1vtEvQu2frMLvHqFylnGd5Gy64qkQT4KRhMsfZctX4z5VzTAgMBAAE=\n-----END RSA PUBLIC KEY-----\n',
    }

    REPOSITORY = {
      'repo' => {
        'id' => 119756,
        'slug' => 'travis-ci/travis-api',
        'description' => 'The public Travis API',
        'last_build_id' => 6347735,
        'last_build_number' => '468',
        'last_build_state' => 'started',
        'last_build_duration' => nil,
        'last_build_language' => nil,
        'last_build_started_at' => '2013-04-15T09:45:29Z',
        'last_build_finished_at' => nil,
      }
    }

    REPOSITORIES = { 'repos' => [ REPOSITORY['repo'] ] }

    SHORT_BUILD = {
      'id' => 6347735,
      'repository_id' => 119756,
      'commit_id' => 1873023,
      'number' => '468',
      'pull_request' => false,
      'pull_request_title' => nil,
      'pull_request_number' => nil,
      'config' => {
        'language' => 'ruby',
        'rvm' => [
          '1.9.3',
          'rbx-19mode',
          'jruby-19mode',
        ],
        'before_script' => [
          'RAILS_ENV=test rake db:create db:schema:load --trace',
        ],
        'notifications' => {
          'irc' => 'irc.freenode.org#travis',
        },
        'matrix' => {
          'allow_failures' => [
            {
              'rvm' => 'rbx-19mode',
            },
            {
              'rvm' => 'jruby-19mode',
            },
          ],
        },
        '.result' => 'configured',
      },
      'state' => 'passed',
      'started_at' => '2013-04-15T09:45:29Z',
      'finished_at' => '2013-04-15T09:49:42Z',
      'duration' => 489,
      'job_ids' => [
        6347736,
        6347737,
        6347738,
      ],
    }

    COMMIT = {
      'id' => 1873023,
      'sha' => 'a18f211f6f921affd1ecd8c18691b40d9948aae5',
      'branch' => 'master',
      'message' => "Merge pull request #25 from henrikhodne/add-responses-to-documentation\n\nAdd responses to documentation",
      'committed_at' => '2013-04-15T09:44:31Z',
      'author_name' => 'Henrik Hodne',
      'author_email' => 'me@henrikhodne.com',
      'committer_name' => 'Henrik Hodne',
      'committer_email' => 'me@henrikhodne.com',
      'compare_url' => 'https://github.com/travis-ci/travis-api/compare/0f31ff4fb6aa...a18f211f6f92',
      'pull_request_number' => nil,
    }

    BUILDS = {
      'builds' => [
        SHORT_BUILD
      ],
      'commits' => [
        COMMIT
      ]
    }

    JOB = {
      'id' => 6347736,
      'repository_id' => 119756,
      'build_id' => 6347735,
      'commit_id' => 1873023,
      'log_id' => 1219815,
      'state' => 'passed',
      'number' => '468.1',
      'config' => {
        'language' => 'ruby',
        'rvm' => '1.9.3',
        'before_script' => [
          'RAILS_ENV=test rake db:create db:schema:load --trace',
        ],
        'notifications' => {
          'irc' => 'irc.freenode.org#travis',
        },
        'matrix' => {
          'allow_failures' => [
            {
              'rvm' => 'rbx-19mode',
            },
            {
              'rvm' => 'jruby-19mode',
            }
          ]
        },
        '.result' => 'configured'
      },
      'started_at' => '2013-04-15T09:45:29Z',
      'finished_at' => '2013-04-15T09:48:14Z',
      'queue' => 'builds.linux',
      'allow_failure' => false,
      'tags' => '',
    }

    BUILD = {
      'build' => SHORT_BUILD,
      'commit' => COMMIT,
      'jobs' => [ JOB ]
    }
  end
end

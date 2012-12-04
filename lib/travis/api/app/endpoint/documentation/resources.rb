require 'json'

class Travis::Api::App::Endpoint
  module Resources
    module Helpers
      def self.json(key)
        JSON.pretty_generate(Resources.const_get(key.to_s.upcase))
      end
    end

    REPOSITORY_KEY = {
      "public_key" => "-----BEGIN RSA PUBLIC KEY-----\nMIGJAoGBAOcx131amMqIzm5+FbZz+DhIgSDbFzjKKpzaN5UWVCrLSc57z64xxTV6\nkaOTZmjCWz6WpaPkFZY+czfL7lmuZ/Y6UNm0vupvdZ6t27SytFFGd1/RJlAe89tu\nGcIrC1vtEvQu2frMLvHqFylnGd5Gy64qkQT4KRhMsfZctX4z5VzTAgMBAAE=\n-----END RSA PUBLIC KEY-----\n",
    }

    REPOSITORY = {
      "id" => 59,
      "slug" => "travis-ci/travis-ci",
      "description" => "A distributed build system for the open source community.",
      "public_key" => REPOSITORY_KEY["public_key"],
      "last_build_id" => 3373911,
      "last_build_number" => "2188",
      "last_build_status" => 0,
      "last_build_result" => 0,
      "last_build_duration" => 221,
      "last_build_language" => nil,
      "last_build_started_at" => "2012-11-27T01:01:28Z",
      "last_build_finished_at" => "2012-11-27T01:05:09Z",
    }

    REPOSITORIES = [REPOSITORY]

    SHORT_BUILD = {
      "id" => 3373911,
      "repository_id" => 59,
      "number" => "2188",
      "state" => "finished",
      "result" => 0,
      "started_at" => "2012-11-27T01:01:28Z",
      "finished_at" => "2012-11-27T01:05:09Z",
      "duration" => 221,
      "commit" => "a0e4dada7eb30b41817d9d3c5222b519502ef87a",
      "branch" => "master",
      "message" => "no need to set up services",
      "event_type" => "push",
    }

    BUILDS = [
      SHORT_BUILD,
    ]

    CONFIG = {
      "language" => "ruby",
      "rvm" => [
        "1.9.3",
      ],
      "bundler_args" => "--without development",
      "before_install" => [
        "gem install bundler --pre",
      ],
      "before_script" => [
        "cp config/database.example.yml config/database.yml"
      ],
      "script" => "RAILS_ENV=test bundle exec rake test:ci --trace",
      "notifications" => {
        "irc" => "irc.freenode.org#travis",
        "campfire" => {
          "secure" => "JJezWGD9KJY/LC2aznI3Zyohy31VTIhcTKX7RWR4C/C8YKbW9kZv3xV6Vn11\nSHxJTeZo6st2Bpv6tjlWZ+HCR09kyCNavIChedla3+oHOiuL0D4gSo+gkTNW\nUKYZz9mcQUd9RoQpTeyxvdvX+l7z62/7JwFA7txHOqxbTS8jrjc="
        }
      },
      ".result" => "configured"
    }

    BUILD = SHORT_BUILD.merge({
      "config" => CONFIG,
      "committed_at" => "2012-11-27T01:01:06Z",
      "author_name" => "Sven Fuchs",
      "author_email" => "me@svenfuchs.com",
      "committer_name" => "Sven Fuchs",
      "committer_email" => "me@svenfuchs.com",
      "compare_url" => "https://github.com/travis-ci/travis-ci/compare/18b6874865f2...a0e4dada7eb3",
      "matrix" => [
        {
          "id" => 3373912,
          "repository_id" => 59,
          "number" => "2188.1",
          "config" => CONFIG,
          "result" => 0,
          "started_at" => "2012-11-27T01:01:28Z",
          "finished_at" => "2012-11-27T01:05:09Z",
          "allow_failure" => false
        }
      ]
    })
  end
end

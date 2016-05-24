API_PAYLOADS = {
  'custom' => {
    'repository' => {
      'owner_id' => 2208,
      'owner_type' => 'User',
      'owner_name' => 'svenfuchs',
      'name' => 'gem-release'
    },
    'branch' => 'master',
    'config' => {
      'env' => ['FOO=foo', 'BAR=bar']
    },
    'user' => {
      'id' => 1
    }
  }
}

GITHUB_PAYLOADS = {
  "private-repo" => %({
    "repository": {
      "url": "http://github.com/svenfuchs/gem-release",
      "name": "gem-release",
      "private":true,
      "owner": {
        "email": "svenfuchs@artweb-design.de",
        "name": "svenfuchs"
      }
    },
    "commits": [{
      "id":        "9854592",
      "message":   "Bump to 0.0.15",
      "timestamp": "2010-10-27T04:32:37Z",
      "committer": {
        "name":  "Sven Fuchs",
        "email": "svenfuchs@artweb-design.de"
      },
      "author": {
        "name":  "Christopher Floess",
        "email": "chris@flooose.de"
      }
    }],
    "ref": "refs/heads/master"
  }),

  "gem-release" => %({
    "repository": {
      "id": 100,
      "url": "http://github.com/svenfuchs/gem-release",
      "name": "gem-release",
      "description": "Release your gems with ease",
      "owner": {
        "id": "2208",
        "email": "svenfuchs@artweb-design.de",
        "name": "svenfuchs"
      }
    },
    "commits": [{
      "id":        "586374eac43853e5542a2e2faafd48047127e4be",
      "message":   "Update the readme",
      "timestamp": "2010-10-14T04:00:37Z",
      "committer": {
        "name":  "Sven Fuchs",
        "email": "svenfuchs@artweb-design.de"
      },
      "author": {
        "name":  "Christopher Floess",
        "email": "chris@flooose.de"
      }
    },{
      "id":        "46ebe012ef3c0be5542a2e2faafd48047127e4be",
      "message":   "Bump to 0.0.15",
      "timestamp": "2010-10-27T04:32:37Z",
      "committer": {
        "name":  "Sven Fuchs",
        "email": "svenfuchs@artweb-design.de"
      },
      "author": {
        "name":  "Christopher Floess",
        "email": "chris@flooose.de"
      }
    }],
    "ref": "refs/heads/master",
    "compare": "https://github.com/svenfuchs/gem-release/compare/af674bd...9854592"
  }),

  "skip-last" => %({
    "repository": {
      "url": "http://github.com/svenfuchs/gem-release",
      "name": "gem-release",
      "description": "Release your gems with ease",
      "owner": {
        "email": "svenfuchs@artweb-design.de",
        "name": "svenfuchs"
      }
    },
    "commits": [{
      "id":        "60aaa2faaa5fdbd87719a10e308d396b828e5a01",
      "message":   "Bump to 0.0.14",
      "timestamp": "2010-10-12T08:47:06Z",
      "committer": {
        "name":  "Sven Fuchs",
        "email": "svenfuchs@artweb-design.de"
      },
      "author": {
        "name":  "Sven Fuchs",
        "email": "svenfuchs@artweb-design.de"
      }
    },{
      "id":        "586374eac43853e5542a2e2faafd48047127e4be",
      "message":   "Update the readme",
      "timestamp": "2010-10-14T04:00:37Z",
      "committer": {
        "name":  "Sven Fuchs",
        "email": "svenfuchs@artweb-design.de"
      },
      "author": {
        "name":  "Christopher Floess",
        "email": "chris@flooose.de"
      }
    },{
      "id":        "46ebe012ef3c0be5542a2e2faafd48047127e4be",
      "message":   "Bump to 0.0.15\\n\\n[ci skip]",
      "timestamp": "2010-10-27T04:32:37Z",
      "committer": {
        "name":  "Sven Fuchs",
        "email": "svenfuchs@artweb-design.de"
      },
      "author": {
        "name":  "Christopher Floess",
        "email": "chris@flooose.de"
      }
    }],
    "ref": "refs/heads/master",
    "compare": "https://github.com/svenfuchs/gem-release/compare/af674bd...9854592"
  }),

  "skip-all" => %({
    "repository": {
      "url": "http://github.com/svenfuchs/gem-release",
      "name": "gem-release",
      "description": "Release your gems with ease",
      "owner": {
        "email": "svenfuchs@artweb-design.de",
        "name": "svenfuchs"
      }
    },
    "commits": [{
      "id":        "60aaa2faaa5fdbd87719a10e308d396b828e5a01",
      "message":   "Bump to 0.0.14\\n\\n[ci skip]",
      "timestamp": "2010-10-12T08:47:06Z",
      "committer": {
        "name":  "Sven Fuchs",
        "email": "svenfuchs@artweb-design.de"
      },
      "author": {
        "name":  "Sven Fuchs",
        "email": "svenfuchs@artweb-design.de"
      }
    },{
      "id":        "586374eac43853e5542a2e2faafd48047127e4be",
      "message":   "Update the readme\\n\\n[ci skip]",
      "timestamp": "2010-10-14T04:00:37Z",
      "committer": {
        "name":  "Sven Fuchs",
        "email": "svenfuchs@artweb-design.de"
      },
      "author": {
        "name":  "Christopher Floess",
        "email": "chris@flooose.de"
      }
    },{
      "id":        "46ebe012ef3c0be5542a2e2faafd48047127e4be",
      "message":   "Bump to 0.0.15\\n\\n[ci skip]",
      "timestamp": "2010-10-27T04:32:37Z",
      "committer": {
        "name":  "Sven Fuchs",
        "email": "svenfuchs@artweb-design.de"
      },
      "author": {
        "name":  "Christopher Floess",
        "email": "chris@flooose.de"
      }
    }],
    "ref": "refs/heads/master",
    "compare": "https://github.com/svenfuchs/gem-release/compare/af674bd...9854592"
  }),


  "travis-core" => %({
    "repository": {
      "id": 111,
      "url": "http://github.com/travis-ci/travis-core",
      "name": "travis-core",
      "description": "description for travis-core",
      "organization": "travis-ci",
      "owner": {
        "email": "contact@travis-ci.org",
        "name": "travis-ci"
      }
    },
    "commits": [{
      "id":        "46ebe012ef3c0be5542a2e2faafd48047127e4be",
      "message":   "Bump to 0.0.15",
      "timestamp": "2010-10-27T04:32:37Z",
      "committer": {
        "name":  "Sven Fuchs",
        "email": "svenfuchs@artweb-design.de"
      },
      "author": {
        "name":  "Josh Kalderimis",
        "email": "josh@email.org"
      }
    }],
    "ref": "refs/heads/master",
    "compare": "https://github.com/travis-ci/travis-core/compare/af674bd...9854592"
  }),

  "travis-core-no-commit" => %({
    "repository": {
      "url": "http://github.com/travis-ci/travis-core",
      "name": "travis-core",
      "description": "description for travis-core",
      "organization": "travis-ci",
      "owner": {
        "email": "contact@travis-ci.org",
        "name": "travis-ci"
      }
    },
    "commits":[],
    "ref": "refs/heads/master",
    "compare": "https://github.com/travis-ci/travis-core/compare/af674bd...9854592"
  }),

  "gh-pages-update" => %({
    "repository": {
      "url": "http://github.com/svenfuchs/gem-release",
      "name": "gem-release",
      "owner": {
        "email": "svenfuchs@artweb-design.de",
        "name": "svenfuchs"
      }
    },
    "commits": [{
      "id":        "9854592",
      "message":   "Bump to 0.0.15",
      "timestamp": "2010-10-27T04:32:37Z",
      "committer": {
        "name":  "Sven Fuchs",
        "email": "svenfuchs@artweb-design.de"
      },
      "author": {
        "name":  "Christopher Floess",
        "email": "chris@flooose.de"
      }
    }],
    "ref": "refs/heads/gh-pages"
  }),

  "gh_pages-update" => %({
    "repository": {
      "url": "http://github.com/svenfuchs/gem-release",
      "name": "gem-release",
      "owner": {
        "email": "svenfuchs@artweb-design.de",
        "name": "svenfuchs"
      }
    },
    "commits": [{
      "id":        "46ebe012ef3c0be5542a2e2faafd48047127e4be",
      "message":   "Bump to 0.0.15",
      "timestamp": "2010-10-27T04:32:37Z",
      "committer": {
        "name":  "Sven Fuchs",
        "email": "svenfuchs@artweb-design.de"
      },
      "author": {
        "name":  "Christopher Floess",
        "email": "chris@flooose.de"
      }
    }],
    "ref": "refs/heads/gh_pages"
  }),

  # it is unclear why this payload was send but it happened quite often. the force option
  # seems to indicate something like $ git push --force
  "force-no-commit" => %({
    "pusher": { "name": "LTe", "email":"lite.88@gmail.com" },
    "repository":{
      "name":"acts-as-messageable",
      "created_at":"2010/08/02 07:41:30 -0700",
      "has_wiki":true,
      "size":200,
      "private":false,
      "watchers":13,
      "fork":false,
      "url":"https://github.com/LTe/acts-as-messageable",
      "language":"Ruby",
      "pushed_at":"2011/05/31 04:16:01 -0700",
      "open_issues":0,
      "has_downloads":true,
      "homepage":"http://github.com/LTe/acts-as-messageable",
      "has_issues":true,
      "forks":5,
      "description":"ActsAsMessageable",
      "owner": { "name":"LTe", "email":"lite.88@gmail.com" }
    },
    "ref_name":"v0.3.0",
    "forced":true,
    "after":"b842078c2f0084bb36cea76da3dad09129b3c26b",
    "deleted":false,
    "ref":"refs/tags/v0.3.0",
    "commits":[],
    "base_ref":"refs/heads/master",
    "before":"0000000000000000000000000000000000000000",
    "compare":"https://github.com/LTe/acts-as-messageable/compare/v0.3.0",
    "created":true
  }),

  "pull-request" => %({
    "action": "opened",
    "number": 1,
    "pull_request": {
      "deletions": 1,
      "merged_by": null,
      "comments": 0,
      "updated_at": "2012-04-12T17:02:33Z",
      "state": "open",
      "diff_url": "https://github.com/travis-repos/test-project-1/pull/1.diff",
      "_links": {
        "comments": {
          "href": "https://api.github.com/repos/travis-repos/test-project-1/issues/1/comments"
        },
        "review_comments": {
          "href": "https://api.github.com/repos/travis-repos/test-project-1/pulls/1/comments"
        },
        "self": {
          "href": "https://api.github.com/repos/travis-repos/test-project-1/pulls/1"
        },
        "html": {
          "href": "https://github.com/travis-repos/test-project-1/pull/1"
        }
      },
      "merged_at": null,
      "user": {
        "gravatar_id": "5c2b452f6eea4a6d84c105ebd971d2a4",
        "url": "https://api.github.com/users/rkh",
        "avatar_url": "https://secure.gravatar.com/avatar/5c2b452f6eea4a6d84c105ebd971d2a4?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png",
        "id": 30442,
        "login": "rkh"
      },
      "issue_url": "https://github.com/travis-repos/test-project-1/issues/1",
      "commits": 1,
      "changed_files": 1,
      "title": "You must enter a title to submit a Pull Request",
      "merged": false,
      "closed_at": null,
      "created_at": "2012-02-14T14:00:48Z",
      "patch_url": "https://github.com/travis-repos/test-project-1/pull/1.patch",
      "url": "https://api.github.com/repos/travis-repos/test-project-1/pulls/1",
      "base": {
        "repo": {
          "pushed_at": "2012-04-11T15:50:22Z",
          "homepage": "http://travis-ci.org",
          "svn_url": "https://github.com/travis-repos/test-project-1",
          "has_issues": false,
          "updated_at": "2012-04-11T15:50:22Z",
          "forks": 6,
          "has_downloads": true,
          "ssh_url": "git@github.com:travis-repos/test-project-1.git",
          "language": "Ruby",
          "clone_url": "https://github.com/travis-repos/test-project-1.git",
          "fork": false,
          "git_url": "git://github.com/travis-repos/test-project-1.git",
          "created_at": "2011-04-14T18:23:41Z",
          "url": "https://api.github.com/repos/travis-repos/test-project-1",
          "has_wiki": false,
          "size": 140,
          "private": false,
          "description": "Test dummy repository for testing Travis CI",
          "owner": {
            "gravatar_id": "dad32d44d4850d2bc9485ee115ab4227",
            "url": "https://api.github.com/users/travis-repos",
            "avatar_url": "https://secure.gravatar.com/avatar/dad32d44d4850d2bc9485ee115ab4227?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-orgs.png",
            "id": 864347,
            "login": "travis-repos"
          },
          "name": "test-project-1",
          "full_name": "travis-repos/test-project-1",
          "watchers": 8,
          "html_url": "https://github.com/travis-repos/test-project-1",
          "id": 1615549,
          "open_issues": 3,
          "mirror_url": null
        },
        "sha": "4a90c0ad9187c8735e1bcbf39a0291a21284994a",
        "label": "travis-repos:master",
        "user": {
          "gravatar_id": "dad32d44d4850d2bc9485ee115ab4227",
          "url": "https://api.github.com/users/travis-repos",
          "avatar_url": "https://secure.gravatar.com/avatar/dad32d44d4850d2bc9485ee115ab4227?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-orgs.png",
          "id": 864347,
          "login": "travis-repos"
        },
        "ref": "master"
      },
      "number": 1,
      "review_comments": 0,
      "head": {
        "repo": {
          "pushed_at": "2012-02-14T14:00:26Z",
          "homepage": "http://travis-ci.org",
          "svn_url": "https://github.com/rkh/test-project-1",
          "has_issues": false,
          "updated_at": "2012-02-14T14:00:27Z",
          "forks": 0,
          "has_downloads": true,
          "ssh_url": "git@github.com:rkh/test-project-1.git",
          "language": "Ruby",
          "clone_url": "https://github.com/rkh/test-project-1.git",
          "fork": true,
          "git_url": "git://github.com/rkh/test-project-1.git",
          "created_at": "2012-02-13T15:17:57Z",
          "url": "https://api.github.com/repos/rkh/test-project-1",
          "has_wiki": true,
          "size": 108,
          "private": false,
          "description": "Test dummy repository for testing Travis CI",
          "owner": {
            "gravatar_id": "5c2b452f6eea4a6d84c105ebd971d2a4",
            "url": "https://api.github.com/users/rkh",
            "avatar_url": "https://secure.gravatar.com/avatar/5c2b452f6eea4a6d84c105ebd971d2a4?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png",
            "id": 30442,
            "login": "rkh"
          },
          "name": "test-project-1",
          "full_name": "rkh/test-project-1",
          "watchers": 1,
          "html_url": "https://github.com/rkh/test-project-1",
          "id": 3431064,
          "open_issues": 0,
          "mirror_url": null
        },
        "sha": "9b00989b1a0e7d9b609ad2e28338c060f79a71ac",
        "label": "rkh:master",
        "user": {
          "gravatar_id": "5c2b452f6eea4a6d84c105ebd971d2a4",
          "url": "https://api.github.com/users/rkh",
          "avatar_url": "https://secure.gravatar.com/avatar/5c2b452f6eea4a6d84c105ebd971d2a4?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png",
          "id": 30442,
          "login": "rkh"
        },
        "ref": "master"
      },
      "body": "",
      "html_url": "https://github.com/travis-repos/test-project-1/pull/1",
      "id": 826379,
      "mergeable": true,
      "mergeable_state": "clean",
      "additions": 1
    },
    "repository": {
      "created_at": "2011-04-14T18:23:41Z",
      "id": 1615549,
      "name": "test-project-1",
      "owner": {
        "avatar_url": "https:\/\/secure.gravatar.com\/avatar\/dad32d44d4850d2bc9485ee115ab4227?d=https:\/\/a248.e.akamai.net\/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-orgs.png",
        "gravatar_id": "dad32d44d4850d2bc9485ee115ab4227",
        "id": 864347,
        "login": "travis-repos",
        "url": "https:\/\/api.github.com\/users\/travis-repos"
      },
      "pushed_at": "2011-12-12T06:38:20Z",
      "updated_at": "2012-02-13T15:17:57Z",
      "url": "https:\/\/api.github.com\/repos\/travis-repos\/test-project-1"
    },
    "sender": {
      "avatar_url": "https:\/\/secure.gravatar.com\/avatar\/5c2b452f6eea4a6d84c105ebd971d2a4?d=https:\/\/a248.e.akamai.net\/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png",
      "gravatar_id": "5c2b452f6eea4a6d84c105ebd971d2a4",
      "id": 30442,
      "login": "rkh",
      "url": "https:\/\/api.github.com\/users\/rkh"
    }
  }),

  'hook_inactive' => %({
    "last_response": {
      "status": "ok",
      "message": "",
      "code": 200
    },
    "config": {
      "domain": "staging.travis-ci.org",
      "user": "svenfuchs",
      "token": "token"
    },
    "created_at": "2011-09-18T10:49:06Z",
    "events": [
      "push",
      "pull_request",
      "issue_comment",
      "public",
      "member"
    ],
    "active": false,
    "updated_at": "2012-08-09T09:32:42Z",
    "name": "travis",
    "_links": {
      "self": {
        "href": "https://api.github.com/repos/svenfuchs/minimal/hooks/77103"
      }
    },
    "id": 77103
  }),

  'hook_active' => %({
    "last_response": {
      "status": "ok",
      "message": "",
      "code": 200
    },
    "config": {
      "domain": "staging.travis-ci.org",
      "user": "svenfuchs",
      "token": "token"
    },
    "created_at": "2011-09-18T10:49:06Z",
    "events": [
      "push",
      "pull_request",
      "issue_comment",
      "public",
      "member"
    ],
    "active": true,
    "updated_at": "2012-08-09T09:32:42Z",
    "name": "travis",
    "_links": {
      "self": {
        "href": "https://api.github.com/repos/svenfuchs/minimal/hooks/77103"
      }
    },
    "id": 77103
  }),

  'rkh' => %({
    "user": {
      "gravatar_id":"5c2b452f6eea4a6d84c105ebd971d2a4",
      "company":"Travis GmbH",
      "name":"Konstantin Haase",
      "created_at":"2008/10/22 11:56:03 -0700",
      "location":"Potsdam, Berlin, Portland",
      "public_repo_count":108,
      "public_gist_count":217,
      "blog":"http://rkh.im",
      "following_count":477,
      "id":30442,
      "type":"User",
      "permission":null,
      "followers_count":369,
      "login":"rkh",
      "email":"k.haase@finn.de"
    }
  }),

  :oauth => {
    "uid" => "234423",
    "info" => {
      "name" => "John",
      "nickname" => "john",
      "email" => "john@email.com"
    },
    "credentials" => {
      "token" => "1234567890abcdefg"
    },
    "extra" => {
      "raw_info" => {
        "gravatar_id" => "41193cdbffbf06be0cdf231b28c54b18"
      }
    }
  },
}

GITHUB_OAUTH_DATA = {
  'name'               => 'John',
  'email'              => 'john@email.com',
  'login'              => 'john',
  'github_id'          => 234423,
  'github_oauth_token' => '1234567890abcdefg',
  'gravatar_id'        => '41193cdbffbf06be0cdf231b28c54b18'
}

WORKER_PAYLOADS = {
  'job:test:receive' => { 'id' => 1, 'state' => 'received',  'received_at'  => '2011-01-01 00:02:00 +0200', 'worker' => 'ruby3.worker.travis-ci.org:travis-ruby-4' },
  'job:test:start'   => { 'id' => 1, 'state' => 'started',  'started_at'  => '2011-01-01 00:02:00 +0200', 'worker' => 'ruby3.worker.travis-ci.org:travis-ruby-4' },
  'job:test:log'     => { 'id' => 1, 'log' => '... appended' },
  'job:test:log:1'   => { 'id' => 1, 'log' => 'the '  },
  'job:test:log:2'   => { 'id' => 1, 'log' => 'full ' },
  'job:test:log:3'   => { 'id' => 1, 'log' => 'log'   },
  'job:test:finish'  => { 'id' => 1, 'state' => 'passed', 'finished_at' => '2011-01-01 00:03:00 +0200', 'log' => 'the full log' },
  'job:test:reset'   => { 'id' => 1 }
}

WORKER_LEGACY_PAYLOADS = {
  'job:test:finished' => { 'id' => 1, 'state' => 'finished', 'finished_at' => '2011-01-01 00:03:00 +0200', 'result' => 0, 'log' => 'the full log' }
}

QUEUE_PAYLOADS = {
  'job:configure' => {
    :type       => 'configure',
    :repository => { :slug => 'travis-ci/travis-ci' },
    :build      => { :id => 1, :commit => '313f61b', :config_url => 'https://raw.github.com/travis-ci/travis-ci/313f61b/.travis.yml' }
  },
  'job:test:1' => {
    :build      => { :id => 2, :number => '1.1', :commit => '9854592', :branch => 'master', :config => { :rvm => '1.8.7' } },
    :repository => { :id => 1, :slug => 'svenfuchs/gem-release' },
    :queue      => 'builds.linux'
  },
  'job:test:2' => {
    :build      => { :id => 3, :number => '1.2', :commit => '9854592', :branch => 'master', :config => { :rvm => '1.9.2' } },
    :repository => { :id => 1, :slug => 'svenfuchs/gem-release' },
    :queue      => 'builds.linux'
  }
}

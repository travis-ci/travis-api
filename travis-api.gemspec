# encoding: utf-8

Gem::Specification.new do |s|
  s.description  = 'The Travis API'
  s.summary      = 'Code running on http://api.travis-ci.org'
  s.name         = 'travis-api'
  s.homepage     = 'http://api.travis-ci.org'
  s.version      = '0.0.1'
  s.require_path = 'lib'

  s.authors = [
    "Sven Fuchs",
    "Konstantin Haase",
    "Piotr Sarnacki",
    "Mathias Meyer",
    "Brian Ford",
    "Henrik Hodne"
  ]

  s.email = [
    "me@svenfuchs.com",
    "konstantin.mailinglists@googlemail.com",
    "drogus@gmail.com",
    "meyer@paperplanes.de",
    "svenfuchs@artweb-design.de",
    "bford@engineyard.com",
    "me@henrikhodne.com"
  ]

  s.files = [
    "Procfile",
    "README.md",
    "Rakefile",
    "config.ru",
    "config/database.yml",
    "config/newrelic.yml",
    "config/unicorn.rb",
    "docs/00_overview.md",
    "docs/01_cross_origin.md",
    "lib/travis/api/app.rb",
    "lib/travis/api/app/access_token.rb",
    "lib/travis/api/app/base.rb",
    "lib/travis/api/app/cors.rb",
    "lib/travis/api/app/endpoint.rb",
    "lib/travis/api/app/endpoint/accounts.rb",
    "lib/travis/api/app/endpoint/artifacts.rb",
    "lib/travis/api/app/endpoint/authorization.rb",
    "lib/travis/api/app/endpoint/branches.rb",
    "lib/travis/api/app/endpoint/broadcasts.rb",
    "lib/travis/api/app/endpoint/builds.rb",
    "lib/travis/api/app/endpoint/documentation.rb",
    "lib/travis/api/app/endpoint/documentation/css/bootstrap-responsive.css",
    "lib/travis/api/app/endpoint/documentation/css/bootstrap-responsive.min.css",
    "lib/travis/api/app/endpoint/documentation/css/bootstrap.css",
    "lib/travis/api/app/endpoint/documentation/css/bootstrap.min.css",
    "lib/travis/api/app/endpoint/documentation/css/prettify.css",
    "lib/travis/api/app/endpoint/documentation/img/glyphicons-halflings-white.png",
    "lib/travis/api/app/endpoint/documentation/img/glyphicons-halflings.png",
    "lib/travis/api/app/endpoint/documentation/img/grid-18px-masked.png",
    "lib/travis/api/app/endpoint/documentation/js/bootstrap.js",
    "lib/travis/api/app/endpoint/documentation/js/bootstrap.min.js",
    "lib/travis/api/app/endpoint/documentation/js/jquery.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-apollo.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-clj.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-css.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-go.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-hs.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-lisp.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-lua.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-ml.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-n.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-proto.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-scala.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-sql.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-tex.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-vb.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-vhdl.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-wiki.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-xq.js",
    "lib/travis/api/app/endpoint/documentation/js/lang-yaml.js",
    "lib/travis/api/app/endpoint/documentation/js/prettify.js",
    "lib/travis/api/app/endpoint/endpoints.rb",
    "lib/travis/api/app/endpoint/events.rb",
    "lib/travis/api/app/endpoint/home.rb",
    "lib/travis/api/app/endpoint/hooks.rb",
    "lib/travis/api/app/endpoint/jobs.rb",
    "lib/travis/api/app/endpoint/repos.rb",
    "lib/travis/api/app/endpoint/requests.rb",
    "lib/travis/api/app/endpoint/stats.rb",
    "lib/travis/api/app/endpoint/users.rb",
    "lib/travis/api/app/endpoint/workers.rb",
    "lib/travis/api/app/extensions.rb",
    "lib/travis/api/app/extensions/scoping.rb",
    "lib/travis/api/app/extensions/smart_constants.rb",
    "lib/travis/api/app/extensions/subclass_tracker.rb",
    "lib/travis/api/app/helpers.rb",
    "lib/travis/api/app/helpers/accept.rb",
    "lib/travis/api/app/helpers/current_user.rb",
    "lib/travis/api/app/helpers/flash.rb",
    "lib/travis/api/app/helpers/mime_types.rb",
    "lib/travis/api/app/helpers/respond_with.rb",
    "lib/travis/api/app/middleware.rb",
    "lib/travis/api/app/middleware/logging.rb",
    "lib/travis/api/app/middleware/rewrite.rb",
    "lib/travis/api/app/middleware/scope_check.rb",
    "lib/travis/api/app/responders.rb",
    "lib/travis/api/app/responders/base.rb",
    "lib/travis/api/app/responders/image.rb",
    "lib/travis/api/app/responders/json.rb",
    "lib/travis/api/app/responders/service.rb",
    "lib/travis/api/app/responders/xml.rb",
    "public/images/result/failing.png",
    "public/images/result/passing.png",
    "public/images/result/unknown.png",
    "script/console",
    "script/server",
    "spec/integration/routes.backup.rb",
    "spec/integration/v1/branches_spec.rb",
    "spec/integration/v1/builds_spec.rb",
    "spec/integration/v1/hooks_spec.rb",
    "spec/integration/v1/jobs_spec.rb",
    "spec/integration/v1/repositories_spec.rb",
    "spec/integration/v1/workers_spec.rb",
    "spec/integration/v1_spec.backup.rb",
    "spec/integration/v2/branches_spec.rb",
    "spec/integration/v2/builds_spec.rb",
    "spec/integration/v2/hooks_spec.rb",
    "spec/integration/v2/jobs_spec.rb",
    "spec/integration/v2/repositories_spec.rb",
    "spec/integration/v2/users_spec.rb",
    "spec/integration/v2/workers_spec.rb",
    "spec/integration/v2_spec.backup.rb",
    "spec/spec_helper.rb",
    "spec/support/matchers.rb",
    "spec/unit/app_spec.rb",
    "spec/unit/cors_spec.rb",
    "spec/unit/default_spec.rb",
    "spec/unit/endpoint/accounts_spec.rb",
    "spec/unit/endpoint/artifacts_spec.rb",
    "spec/unit/endpoint/authorization/user_manager_spec.rb",
    "spec/unit/endpoint/authorization_spec.rb",
    "spec/unit/endpoint/branches_spec.rb",
    "spec/unit/endpoint/builds_spec.rb",
    "spec/unit/endpoint/documentation_spec.rb",
    "spec/unit/endpoint/endpoints_spec.rb",
    "spec/unit/endpoint/hooks_spec.rb",
    "spec/unit/endpoint/jobs_spec.rb",
    "spec/unit/endpoint/repos_spec.rb",
    "spec/unit/endpoint/users_spec.rb",
    "spec/unit/endpoint/workers_spec.rb",
    "spec/unit/endpoint_spec.rb",
    "spec/unit/extensions/scoping_spec.rb",
    "spec/unit/extensions/smart_constants_spec.rb",
    "spec/unit/extensions/subclass_tracker_spec.rb",
    "spec/unit/helpers/json_renderer_spec.rb",
    "spec/unit/middleware/logging_spec.rb",
    "spec/unit/middleware/scope_check_spec.rb",
    "spec/unit/middleware_spec.rb",
    "spec/unit/responders/service_spec.rb",
    "travis-api.gemspec"
  ]

  s.add_dependency 'travis-support'
  s.add_dependency 'travis-core'

  s.add_dependency 'hubble',          '~> 0.1'
  s.add_dependency 'backports',       '~> 2.5'
  s.add_dependency 'pg',              '~> 0.13.2'
  s.add_dependency 'newrelic_rpm',    '~> 3.3.0'
  s.add_dependency 'thin',            '~> 1.4'
  s.add_dependency 'sinatra',         '~> 1.3'
  s.add_dependency 'sinatra-contrib', '~> 1.3'
  s.add_dependency 'redcarpet',       '~> 2.1'
  s.add_dependency 'rack-ssl',        '~> 1.3'
  s.add_dependency 'rack-contrib',    '~> 1.1'
end


# encoding: utf-8

Gem::Specification.new do |s|
  s.description  = 'The Travis API'
  s.summary      = 'Code running on http://api.travis-ci.org'
  s.name         = 'travis-api'
  s.homepage     = 'http://api.travis-ci.org'
  s.version      = '0.0.1'
  s.require_path = 'lib'

  s.authors = [
    "Konstantin Haase",
    "Piotr Sarnacki",
    "carlad",
    "Sven Fuchs",
    "Hiro Asari",
    "Mathias Meyer",
    "Josh Kalderimis",
    "Henrik Hodne",
    "Steffen Kötte",
    "Renée Hendricksen",
    "Tyranja",
    "Ana Rosas",
    "Lennard Wolf",
    "Steffen",
    "Jonas Chromik",
    "Dan Buch",
    "Andre Arko",
    "Christopher Weyand",
    "Erik Michaels-Ober",
    "C. Scott Ananian",
    "Lisa P",
    "Brian Ford",
    "Steve Richert",
    "Nick Schonning",
    "María de Antón",
    "Puneeth Chaganti",
    "Lucas CHERIFI",
    "James Dennes",
    "Igor Wiedler",
    "rainsun",
    "Igor",
    "Thais Camilo and Konstantin Haase",
    "Tim Carey-Smith",
    "Dan Rice",
    "Zachary Scott",
    "Bryan Goldstein",
    "Patrick Williams"
  ]

  s.email = [
    "konstantin.mailinglists@googlemail.com",
    "drogus@gmail.com",
    "carla@travis-ci.com",
    "me@svenfuchs.com",
    "asari.ruby@gmail.com",
    "meyer@paperplanes.de",
    "josh.kalderimis@gmail.com",
    "steffen.koette@gmail.com",
    "carlad@users.noreply.github.com",
    "me@henrikhodne.com",
    "renee@travis-ci.org",
    "henrik@hodne.io",
    "carla@travis-ci.org",
    "tyranja@cassiopeia.uberspace.de",
    "a.rosas10@gmail.com",
    "konstantin.haase@gmail.com",
    "lennardwolf@live.de",
    "steffen.koette@gmail.com",
    "Jonas.Chromik@student.hpi.uni-potsdam.de",
    "dan@travis-ci.org",
    "andre@arko.net",
    "svenfuchs@artweb-design.de",
    "cscott@cscott.net",
    "christopher.weyand@student.hpi.de",
    "sferik@gmail.com",
    "steve.richert@gmail.com",
    "bford@engineyard.com",
    "henrik@travis-ci.com",
    "mail@lislis.de",
    "rainsuner@gmail.com",
    "patrick@bittorrent.com",
    "nschonni@gmail.com",
    "MariadeAnton@users.noreply.github.com",
    "lucas@cherifi.info",
    "jdennes@gmail.com",
    "igor@travis-ci.org",
    "dev+narwen+rkh@rkh.im",
    "tim@spork.in",
    "igorwwwwwwwwwwwwwwwwwwww@users.noreply.github.com",
    "e@zzak.io",
    "dan@zoombody.com",
    "dan@meatballhat.com",
    "brysgo@gmail.com",
    "punchagan@muse-amuse.in"
  ]

  s.files = [
    "CONTRIBUTING.md",
    "LICENSE",
    "Procfile",
    "README.md",
    "Rakefile",
    "bin/start-nginx",
    "config.ru",
    "config/database.yml",
    "config/mime.types",
    "config/nginx.conf.erb",
    "config/puma-config.rb",
    "config/ruby_config.sh",
    "config/unicorn.rb",
    "core_specs/core/model/annotation_provider_spec.rb",
    "core_specs/core/model/annotation_spec.rb",
    "core_specs/core/model/broadcast_spec.rb",
    "core_specs/core/model/build/compat_spec.rb",
    "core_specs/core/model/build/config/dist_spec.rb",
    "core_specs/core/model/build/config/group_spec.rb",
    "core_specs/core/model/build/config/matrix_spec.rb",
    "core_specs/core/model/build/config/obfuscate_spec.rb",
    "core_specs/core/model/build/config_spec.rb",
    "core_specs/core/model/build/denormalize_spec.rb",
    "core_specs/core/model/build/matrix_spec.rb",
    "core_specs/core/model/build/metrics_spec.rb",
    "core_specs/core/model/build/result_message_spec.rb",
    "core_specs/core/model/build/states_spec.rb",
    "core_specs/core/model/build/update_branch_spec.rb",
    "core_specs/core/model/build_spec.rb",
    "core_specs/core/model/commit_spec.rb",
    "core_specs/core/model/encrypted_column_spec.rb",
    "core_specs/core/model/job/cleanup_spec.rb",
    "core_specs/core/model/job/queue_spec.rb",
    "core_specs/core/model/job/test_spec.rb",
    "core_specs/core/model/job_spec.rb",
    "core_specs/core/model/organization_spec.rb",
    "core_specs/core/model/permission_spec.rb",
    "core_specs/core/model/repository/settings/ssh_key_spec.rb",
    "core_specs/core/model/repository/settings_spec.rb",
    "core_specs/core/model/repository/status_image_spec.rb",
    "core_specs/core/model/repository_spec.rb",
    "core_specs/core/model/request/approval_spec.rb",
    "core_specs/core/model/request/branches_spec.rb",
    "core_specs/core/model/request/states_spec.rb",
    "core_specs/core/model/request_spec.rb",
    "core_specs/core/model/ssl_key_spec.rb",
    "core_specs/core/model/token_spec.rb",
    "core_specs/core/model/url_spec.rb",
    "core_specs/core/model/user/oauth_spec.rb",
    "core_specs/core/model/user_spec.rb",
    "core_specs/core/services/cancel_build_spec.rb",
    "core_specs/core/services/cancel_job_spec.rb",
    "core_specs/core/services/find_admin_spec.rb",
    "core_specs/core/services/find_annotation_spec.rb",
    "core_specs/core/services/find_branch_spec.rb",
    "core_specs/core/services/find_branches_spec.rb",
    "core_specs/core/services/find_build_spec.rb",
    "core_specs/core/services/find_builds_spec.rb",
    "core_specs/core/services/find_caches_spec.rb",
    "core_specs/core/services/find_daily_repos_stats_spec.rb",
    "core_specs/core/services/find_daily_tests_stats_spec.rb",
    "core_specs/core/services/find_hooks_spec.rb",
    "core_specs/core/services/find_job_spec.rb",
    "core_specs/core/services/find_jobs_spec.rb",
    "core_specs/core/services/find_log_spec.rb",
    "core_specs/core/services/find_repo_key_spec.rb",
    "core_specs/core/services/find_repo_settings_spec.rb",
    "core_specs/core/services/find_repo_spec.rb",
    "core_specs/core/services/find_repos_spec.rb",
    "core_specs/core/services/find_request_spec.rb",
    "core_specs/core/services/find_requests_spec.rb",
    "core_specs/core/services/find_user_accounts_spec.rb",
    "core_specs/core/services/next_build_number_spec.rb",
    "core_specs/core/services/regenerate_repo_key_spec.rb",
    "core_specs/core/services/remove_log_spec.rb",
    "core_specs/core/services/reset_model_spec.rb",
    "core_specs/core/services/sync_user_spec.rb",
    "core_specs/core/services/update_annotation_spec.rb",
    "core_specs/core/services/update_hook_spec.rb",
    "core_specs/core/services/update_job_spec.rb",
    "core_specs/core/services/update_log_spec.rb",
    "core_specs/core/services/update_user_spec.rb",
    "core_specs/core/services_spec.rb",
    "lib/active_record_postgres_variables.rb",
    "lib/conditional_skylight.rb",
    "lib/tasks/build_update_branch.rake",
    "lib/tasks/build_update_pull_request_data.rake",
    "lib/tasks/encrypt_all_data.rake",
    "lib/travis/api/app.rb",
    "lib/travis/api/app/access_token.rb",
    "lib/travis/api/app/base.rb",
    "lib/travis/api/app/cors.rb",
    "lib/travis/api/app/endpoint.rb",
    "lib/travis/api/app/endpoint/accounts.rb",
    "lib/travis/api/app/endpoint/authorization.rb",
    "lib/travis/api/app/endpoint/branches.rb",
    "lib/travis/api/app/endpoint/broadcasts.rb",
    "lib/travis/api/app/endpoint/builds.rb",
    "lib/travis/api/app/endpoint/documentation.rb",
    "lib/travis/api/app/endpoint/endpoints.rb",
    "lib/travis/api/app/endpoint/env_vars.rb",
    "lib/travis/api/app/endpoint/home.rb",
    "lib/travis/api/app/endpoint/hooks.rb",
    "lib/travis/api/app/endpoint/jobs.rb",
    "lib/travis/api/app/endpoint/lint.rb",
    "lib/travis/api/app/endpoint/logs.rb",
    "lib/travis/api/app/endpoint/repos.rb",
    "lib/travis/api/app/endpoint/requests.rb",
    "lib/travis/api/app/endpoint/setting_endpoint.rb",
    "lib/travis/api/app/endpoint/singleton_settings_endpoint.rb",
    "lib/travis/api/app/endpoint/uptime.rb",
    "lib/travis/api/app/endpoint/users.rb",
    "lib/travis/api/app/error_handling.rb",
    "lib/travis/api/app/extensions.rb",
    "lib/travis/api/app/extensions/expose_pattern.rb",
    "lib/travis/api/app/extensions/scoping.rb",
    "lib/travis/api/app/extensions/smart_constants.rb",
    "lib/travis/api/app/extensions/subclass_tracker.rb",
    "lib/travis/api/app/helpers.rb",
    "lib/travis/api/app/helpers/accept.rb",
    "lib/travis/api/app/helpers/current_user.rb",
    "lib/travis/api/app/helpers/db_follower.rb",
    "lib/travis/api/app/helpers/flash.rb",
    "lib/travis/api/app/helpers/mime_types.rb",
    "lib/travis/api/app/helpers/respond_with.rb",
    "lib/travis/api/app/middleware.rb",
    "lib/travis/api/app/middleware/logging.rb",
    "lib/travis/api/app/middleware/metriks.rb",
    "lib/travis/api/app/middleware/rewrite.rb",
    "lib/travis/api/app/middleware/scope_check.rb",
    "lib/travis/api/app/middleware/skylight.rb",
    "lib/travis/api/app/middleware/skylight/actual.rb",
    "lib/travis/api/app/middleware/skylight/dummy.rb",
    "lib/travis/api/app/middleware/user_agent_tracker.rb",
    "lib/travis/api/app/responders.rb",
    "lib/travis/api/app/responders/atom.rb",
    "lib/travis/api/app/responders/badge.rb",
    "lib/travis/api/app/responders/base.rb",
    "lib/travis/api/app/responders/image.rb",
    "lib/travis/api/app/responders/json.rb",
    "lib/travis/api/app/responders/plain.rb",
    "lib/travis/api/app/responders/service.rb",
    "lib/travis/api/app/responders/xml.rb",
    "lib/travis/api/app/services/schedule_request.rb",
    "lib/travis/api/app/stack_instrumentation.rb",
    "lib/travis/api/attack.rb",
    "lib/travis/api/enqueue/services/enqueue_build.rb",
    "lib/travis/api/instruments.rb",
    "lib/travis/api/serializer.rb",
    "lib/travis/api/v2.rb",
    "lib/travis/api/v2/http.rb",
    "lib/travis/api/v2/http/accounts.rb",
    "lib/travis/api/v2/http/annotations.rb",
    "lib/travis/api/v2/http/branch.rb",
    "lib/travis/api/v2/http/branches.rb",
    "lib/travis/api/v2/http/broadcasts.rb",
    "lib/travis/api/v2/http/build.rb",
    "lib/travis/api/v2/http/builds.rb",
    "lib/travis/api/v2/http/caches.rb",
    "lib/travis/api/v2/http/env_var.rb",
    "lib/travis/api/v2/http/env_vars.rb",
    "lib/travis/api/v2/http/error.rb",
    "lib/travis/api/v2/http/hooks.rb",
    "lib/travis/api/v2/http/job.rb",
    "lib/travis/api/v2/http/jobs.rb",
    "lib/travis/api/v2/http/log.rb",
    "lib/travis/api/v2/http/permissions.rb",
    "lib/travis/api/v2/http/repositories.rb",
    "lib/travis/api/v2/http/repository.rb",
    "lib/travis/api/v2/http/request.rb",
    "lib/travis/api/v2/http/requests.rb",
    "lib/travis/api/v2/http/ssh_key.rb",
    "lib/travis/api/v2/http/ssl_key.rb",
    "lib/travis/api/v2/http/user.rb",
    "lib/travis/api/v2/http/validation_error.rb",
    "lib/travis/api/v3.rb",
    "lib/travis/api/v3/access_control.rb",
    "lib/travis/api/v3/access_control/anonymous.rb",
    "lib/travis/api/v3/access_control/application.rb",
    "lib/travis/api/v3/access_control/generic.rb",
    "lib/travis/api/v3/access_control/legacy_token.rb",
    "lib/travis/api/v3/access_control/scoped.rb",
    "lib/travis/api/v3/access_control/signature.rb",
    "lib/travis/api/v3/access_control/user.rb",
    "lib/travis/api/v3/constant_resolver.rb",
    "lib/travis/api/v3/error.rb",
    "lib/travis/api/v3/extensions/belongs_to.rb",
    "lib/travis/api/v3/extensions/encrypted_column.rb",
    "lib/travis/api/v3/features.rb",
    "lib/travis/api/v3/github.rb",
    "lib/travis/api/v3/metrics.rb",
    "lib/travis/api/v3/model.rb",
    "lib/travis/api/v3/models.rb",
    "lib/travis/api/v3/models/account.rb",
    "lib/travis/api/v3/models/branch.rb",
    "lib/travis/api/v3/models/broadcast.rb",
    "lib/travis/api/v3/models/build.rb",
    "lib/travis/api/v3/models/commit.rb",
    "lib/travis/api/v3/models/cron.rb",
    "lib/travis/api/v3/models/email.rb",
    "lib/travis/api/v3/models/job.rb",
    "lib/travis/api/v3/models/log.rb",
    "lib/travis/api/v3/models/log_part.rb",
    "lib/travis/api/v3/models/membership.rb",
    "lib/travis/api/v3/models/organization.rb",
    "lib/travis/api/v3/models/permission.rb",
    "lib/travis/api/v3/models/repository.rb",
    "lib/travis/api/v3/models/request.rb",
    "lib/travis/api/v3/models/ssl_key.rb",
    "lib/travis/api/v3/models/star.rb",
    "lib/travis/api/v3/models/subscription.rb",
    "lib/travis/api/v3/models/token.rb",
    "lib/travis/api/v3/models/user.rb",
    "lib/travis/api/v3/opt_in.rb",
    "lib/travis/api/v3/paginator.rb",
    "lib/travis/api/v3/paginator/url_generator.rb",
    "lib/travis/api/v3/permissions.rb",
    "lib/travis/api/v3/permissions/account.rb",
    "lib/travis/api/v3/permissions/build.rb",
    "lib/travis/api/v3/permissions/cron.rb",
    "lib/travis/api/v3/permissions/generic.rb",
    "lib/travis/api/v3/permissions/job.rb",
    "lib/travis/api/v3/permissions/organization.rb",
    "lib/travis/api/v3/permissions/repository.rb",
    "lib/travis/api/v3/permissions/user.rb",
    "lib/travis/api/v3/queries.rb",
    "lib/travis/api/v3/queries/accounts.rb",
    "lib/travis/api/v3/queries/branch.rb",
    "lib/travis/api/v3/queries/branches.rb",
    "lib/travis/api/v3/queries/broadcasts.rb",
    "lib/travis/api/v3/queries/build.rb",
    "lib/travis/api/v3/queries/builds.rb",
    "lib/travis/api/v3/queries/cron.rb",
    "lib/travis/api/v3/queries/crons.rb",
    "lib/travis/api/v3/queries/job.rb",
    "lib/travis/api/v3/queries/jobs.rb",
    "lib/travis/api/v3/queries/organization.rb",
    "lib/travis/api/v3/queries/organizations.rb",
    "lib/travis/api/v3/queries/owner.rb",
    "lib/travis/api/v3/queries/repositories.rb",
    "lib/travis/api/v3/queries/repository.rb",
    "lib/travis/api/v3/queries/request.rb",
    "lib/travis/api/v3/queries/requests.rb",
    "lib/travis/api/v3/queries/user.rb",
    "lib/travis/api/v3/query.rb",
    "lib/travis/api/v3/renderer.rb",
    "lib/travis/api/v3/renderer/accepted.rb",
    "lib/travis/api/v3/renderer/account.rb",
    "lib/travis/api/v3/renderer/accounts.rb",
    "lib/travis/api/v3/renderer/avatar_url.rb",
    "lib/travis/api/v3/renderer/branch.rb",
    "lib/travis/api/v3/renderer/branches.rb",
    "lib/travis/api/v3/renderer/broadcast.rb",
    "lib/travis/api/v3/renderer/broadcasts.rb",
    "lib/travis/api/v3/renderer/build.rb",
    "lib/travis/api/v3/renderer/builds.rb",
    "lib/travis/api/v3/renderer/collection_renderer.rb",
    "lib/travis/api/v3/renderer/commit.rb",
    "lib/travis/api/v3/renderer/cron.rb",
    "lib/travis/api/v3/renderer/crons.rb",
    "lib/travis/api/v3/renderer/error.rb",
    "lib/travis/api/v3/renderer/job.rb",
    "lib/travis/api/v3/renderer/jobs.rb",
    "lib/travis/api/v3/renderer/lint.rb",
    "lib/travis/api/v3/renderer/model_renderer.rb",
    "lib/travis/api/v3/renderer/organization.rb",
    "lib/travis/api/v3/renderer/organizations.rb",
    "lib/travis/api/v3/renderer/owner.rb",
    "lib/travis/api/v3/renderer/repositories.rb",
    "lib/travis/api/v3/renderer/repository.rb",
    "lib/travis/api/v3/renderer/request.rb",
    "lib/travis/api/v3/renderer/requests.rb",
    "lib/travis/api/v3/renderer/user.rb",
    "lib/travis/api/v3/result.rb",
    "lib/travis/api/v3/router.rb",
    "lib/travis/api/v3/routes.rb",
    "lib/travis/api/v3/routes/dsl.rb",
    "lib/travis/api/v3/routes/resource.rb",
    "lib/travis/api/v3/service.rb",
    "lib/travis/api/v3/service_index.rb",
    "lib/travis/api/v3/services.rb",
    "lib/travis/api/v3/services/accounts/for_current_user.rb",
    "lib/travis/api/v3/services/branch/find.rb",
    "lib/travis/api/v3/services/branches/find.rb",
    "lib/travis/api/v3/services/broadcasts/for_current_user.rb",
    "lib/travis/api/v3/services/build/cancel.rb",
    "lib/travis/api/v3/services/build/find.rb",
    "lib/travis/api/v3/services/build/restart.rb",
    "lib/travis/api/v3/services/builds/find.rb",
    "lib/travis/api/v3/services/cron/create.rb",
    "lib/travis/api/v3/services/cron/delete.rb",
    "lib/travis/api/v3/services/cron/find.rb",
    "lib/travis/api/v3/services/cron/for_branch.rb",
    "lib/travis/api/v3/services/crons/for_repository.rb",
    "lib/travis/api/v3/services/crons/start.rb",
    "lib/travis/api/v3/services/job/cancel.rb",
    "lib/travis/api/v3/services/job/debug.rb",
    "lib/travis/api/v3/services/job/find.rb",
    "lib/travis/api/v3/services/job/restart.rb",
    "lib/travis/api/v3/services/jobs/find.rb",
    "lib/travis/api/v3/services/lint/lint.rb",
    "lib/travis/api/v3/services/organization/find.rb",
    "lib/travis/api/v3/services/organization/sync.rb",
    "lib/travis/api/v3/services/organizations/for_current_user.rb",
    "lib/travis/api/v3/services/owner/find.rb",
    "lib/travis/api/v3/services/repositories/for_current_user.rb",
    "lib/travis/api/v3/services/repositories/for_owner.rb",
    "lib/travis/api/v3/services/repository/disable.rb",
    "lib/travis/api/v3/services/repository/enable.rb",
    "lib/travis/api/v3/services/repository/find.rb",
    "lib/travis/api/v3/services/repository/star.rb",
    "lib/travis/api/v3/services/repository/unstar.rb",
    "lib/travis/api/v3/services/requests/create.rb",
    "lib/travis/api/v3/services/requests/find.rb",
    "lib/travis/api/v3/services/user/current.rb",
    "lib/travis/api/v3/services/user/find.rb",
    "lib/travis/api/v3/services/user/sync.rb",
    "lib/travis/api/workers/build_cancellation.rb",
    "lib/travis/api/workers/build_restart.rb",
    "lib/travis/api/workers/job_cancellation.rb",
    "lib/travis/api/workers/job_restart.rb",
    "lib/travis/private_key.rb",
    "lib/travis/sidekiq.rb",
    "public/favicon.ico",
    "public/images/result/canceled.png",
    "public/images/result/canceled.svg",
    "public/images/result/error.png",
    "public/images/result/error.svg",
    "public/images/result/failing.png",
    "public/images/result/failing.svg",
    "public/images/result/passing.png",
    "public/images/result/passing.svg",
    "public/images/result/pending.png",
    "public/images/result/pending.svg",
    "public/images/result/unknown.png",
    "public/images/result/unknown.svg",
    "script/console",
    "script/repos_stats.rb",
    "script/server",
    "script/start_crons",
    "script/web_concurrency",
    "spec/active_record_postgres_variables_spec.rb",
    "spec/integration/error_handling_spec.rb",
    "spec/integration/formats_handling_spec.rb",
    "spec/integration/responders_spec.rb",
    "spec/integration/routes.backup.rb",
    "spec/integration/scopes_spec.rb",
    "spec/integration/settings_endpoint_spec.rb",
    "spec/integration/singleton_settings_endpoint_spec.rb",
    "spec/integration/uptime_spec.rb",
    "spec/integration/v2/branches_spec.rb",
    "spec/integration/v2/builds_spec.rb",
    "spec/integration/v2/hooks_spec.rb",
    "spec/integration/v2/jobs_spec.rb",
    "spec/integration/v2/repositories_spec.rb",
    "spec/integration/v2/requests_spec.rb",
    "spec/integration/v2/settings/env_vars_spec.rb",
    "spec/integration/v2/settings/ssh_key_spec.rb",
    "spec/integration/v2/users_spec.rb",
    "spec/integration/v2_spec.backup.rb",
    "spec/integration/version_spec.rb",
    "spec/spec_helper.rb",
    "spec/spec_helper_core.rb",
    "spec/support.rb",
    "spec/support/active_record.rb",
    "spec/support/coverage.rb",
    "spec/support/formats.rb",
    "spec/support/gcs.rb",
    "spec/support/matchers.rb",
    "spec/support/payloads.rb",
    "spec/support/s3.rb",
    "spec/unit/access_token_spec.rb",
    "spec/unit/api/v2/http/accounts_spec.rb",
    "spec/unit/api/v2/http/annotations_spec.rb",
    "spec/unit/api/v2/http/branch_spec.rb",
    "spec/unit/api/v2/http/branches_spec.rb",
    "spec/unit/api/v2/http/broadcasts_spec.rb",
    "spec/unit/api/v2/http/build_spec.rb",
    "spec/unit/api/v2/http/builds_spec.rb",
    "spec/unit/api/v2/http/caches_spec.rb",
    "spec/unit/api/v2/http/env_var_spec.rb",
    "spec/unit/api/v2/http/hooks_spec.rb",
    "spec/unit/api/v2/http/job_spec.rb",
    "spec/unit/api/v2/http/jobs_spec.rb",
    "spec/unit/api/v2/http/log_spec.rb",
    "spec/unit/api/v2/http/permissions_spec.rb",
    "spec/unit/api/v2/http/repositories_spec.rb",
    "spec/unit/api/v2/http/repository_spec.rb",
    "spec/unit/api/v2/http/request_spec.rb",
    "spec/unit/api/v2/http/requests_spec.rb",
    "spec/unit/api/v2/http/ssl_key_spec.rb",
    "spec/unit/api/v2/http/user_spec.rb",
    "spec/unit/app_spec.rb",
    "spec/unit/cors_spec.rb",
    "spec/unit/default_spec.rb",
    "spec/unit/endpoint/accounts_spec.rb",
    "spec/unit/endpoint/authorization/user_manager_spec.rb",
    "spec/unit/endpoint/authorization_spec.rb",
    "spec/unit/endpoint/branches_spec.rb",
    "spec/unit/endpoint/builds_spec.rb",
    "spec/unit/endpoint/endpoints_spec.rb",
    "spec/unit/endpoint/hooks_spec.rb",
    "spec/unit/endpoint/jobs_spec.rb",
    "spec/unit/endpoint/lint_spec.rb",
    "spec/unit/endpoint/logs_spec.rb",
    "spec/unit/endpoint/repos_spec.rb",
    "spec/unit/endpoint/requests/throttle_spec.rb",
    "spec/unit/endpoint/users_spec.rb",
    "spec/unit/endpoint_spec.rb",
    "spec/unit/extensions/expose_pattern_spec.rb",
    "spec/unit/extensions/scoping_spec.rb",
    "spec/unit/extensions/smart_constants_spec.rb",
    "spec/unit/extensions/subclass_tracker_spec.rb",
    "spec/unit/helpers/accept_spec.rb",
    "spec/unit/helpers/json_renderer_spec.rb",
    "spec/unit/middleware/logging_spec.rb",
    "spec/unit/middleware/scope_check_spec.rb",
    "spec/unit/middleware/user_agent_tracker_spec.rb",
    "spec/unit/responders/json_spec.rb",
    "spec/unit/responders/service_spec.rb",
    "spec/v3/error_handling_spec.rb",
    "spec/v3/extensions/belongs_to_spec.rb",
    "spec/v3/metrics_spec.rb",
    "spec/v3/models/cron_spec.rb",
    "spec/v3/queries/cron_spec.rb",
    "spec/v3/renderer/avatar_url_spec.rb",
    "spec/v3/result_spec.rb",
    "spec/v3/service_index_spec.rb",
    "spec/v3/services/accounts/for_current_user_spec.rb",
    "spec/v3/services/branch/find_spec.rb",
    "spec/v3/services/branches/find_spec.rb",
    "spec/v3/services/broadcasts/for_current_user_spec.rb",
    "spec/v3/services/build/cancel_spec.rb",
    "spec/v3/services/build/find_spec.rb",
    "spec/v3/services/build/restart_spec.rb",
    "spec/v3/services/builds/find_spec.rb",
    "spec/v3/services/cron/create_spec.rb",
    "spec/v3/services/cron/delete_spec.rb",
    "spec/v3/services/cron/find_spec.rb",
    "spec/v3/services/cron/for_branch_spec.rb",
    "spec/v3/services/crons/for_repository_spec.rb",
    "spec/v3/services/job/cancel_spec.rb",
    "spec/v3/services/job/debug_sepc.rb",
    "spec/v3/services/job/find_spec.rb",
    "spec/v3/services/job/restart_spec.rb",
    "spec/v3/services/jobs/find_spec.rb",
    "spec/v3/services/lint/lint_spec.rb",
    "spec/v3/services/organization/find_spec.rb",
    "spec/v3/services/organizations/for_current_user_spec.rb",
    "spec/v3/services/owner/find_spec.rb",
    "spec/v3/services/repositories/for_current_user_spec.rb",
    "spec/v3/services/repositories/for_owner_spec.rb",
    "spec/v3/services/repository/disable_spec.rb",
    "spec/v3/services/repository/enable_spec.rb",
    "spec/v3/services/repository/find_spec.rb",
    "spec/v3/services/repository/star_spec.rb",
    "spec/v3/services/repository/unstar_spec.rb",
    "spec/v3/services/requests/create_spec.rb",
    "spec/v3/services/requests/find_spec.rb",
    "spec/v3/services/user/current_spec.rb",
    "spec/v3/services/user/find_spec.rb",
    "spec/v3/services/user/sync_spec.rb",
    "tmp/.gitkeep",
    "travis-api.gemspec",
    "vendor/travis-core/lib/travis.rb",
    "vendor/travis-core/lib/travis/README.markdown",
    "vendor/travis-core/lib/travis/addons.rb",
    "vendor/travis-core/lib/travis/addons/README.markdown",
    "vendor/travis-core/lib/travis/addons/archive.rb",
    "vendor/travis-core/lib/travis/addons/archive/event_handler.rb",
    "vendor/travis-core/lib/travis/addons/archive/task.rb",
    "vendor/travis-core/lib/travis/addons/campfire.rb",
    "vendor/travis-core/lib/travis/addons/campfire/event_handler.rb",
    "vendor/travis-core/lib/travis/addons/campfire/instruments.rb",
    "vendor/travis-core/lib/travis/addons/email.rb",
    "vendor/travis-core/lib/travis/addons/email/event_handler.rb",
    "vendor/travis-core/lib/travis/addons/email/instruments.rb",
    "vendor/travis-core/lib/travis/addons/flowdock.rb",
    "vendor/travis-core/lib/travis/addons/flowdock/event_handler.rb",
    "vendor/travis-core/lib/travis/addons/flowdock/instruments.rb",
    "vendor/travis-core/lib/travis/addons/github_status.rb",
    "vendor/travis-core/lib/travis/addons/github_status/event_handler.rb",
    "vendor/travis-core/lib/travis/addons/github_status/instruments.rb",
    "vendor/travis-core/lib/travis/addons/hipchat.rb",
    "vendor/travis-core/lib/travis/addons/hipchat/event_handler.rb",
    "vendor/travis-core/lib/travis/addons/hipchat/instruments.rb",
    "vendor/travis-core/lib/travis/addons/irc.rb",
    "vendor/travis-core/lib/travis/addons/irc/event_handler.rb",
    "vendor/travis-core/lib/travis/addons/irc/instruments.rb",
    "vendor/travis-core/lib/travis/addons/pusher.rb",
    "vendor/travis-core/lib/travis/addons/pusher/event_handler.rb",
    "vendor/travis-core/lib/travis/addons/pusher/instruments.rb",
    "vendor/travis-core/lib/travis/addons/pushover.rb",
    "vendor/travis-core/lib/travis/addons/pushover/event_handler.rb",
    "vendor/travis-core/lib/travis/addons/pushover/instruments.rb",
    "vendor/travis-core/lib/travis/addons/slack.rb",
    "vendor/travis-core/lib/travis/addons/slack/event_handler.rb",
    "vendor/travis-core/lib/travis/addons/slack/instruments.rb",
    "vendor/travis-core/lib/travis/addons/sqwiggle.rb",
    "vendor/travis-core/lib/travis/addons/sqwiggle/event_handler.rb",
    "vendor/travis-core/lib/travis/addons/sqwiggle/instruments.rb",
    "vendor/travis-core/lib/travis/addons/states_cache.rb",
    "vendor/travis-core/lib/travis/addons/states_cache/event_handler.rb",
    "vendor/travis-core/lib/travis/addons/util.rb",
    "vendor/travis-core/lib/travis/addons/webhook.rb",
    "vendor/travis-core/lib/travis/addons/webhook/event_handler.rb",
    "vendor/travis-core/lib/travis/addons/webhook/instruments.rb",
    "vendor/travis-core/lib/travis/advisory_locks.rb",
    "vendor/travis-core/lib/travis/api.rb",
    "vendor/travis-core/lib/travis/api/README.markdown",
    "vendor/travis-core/lib/travis/api/formats.rb",
    "vendor/travis-core/lib/travis/api/v0.rb",
    "vendor/travis-core/lib/travis/api/v0/event.rb",
    "vendor/travis-core/lib/travis/api/v0/event/build.rb",
    "vendor/travis-core/lib/travis/api/v0/event/job.rb",
    "vendor/travis-core/lib/travis/api/v0/notification.rb",
    "vendor/travis-core/lib/travis/api/v0/notification/build.rb",
    "vendor/travis-core/lib/travis/api/v0/notification/repository.rb",
    "vendor/travis-core/lib/travis/api/v0/notification/user.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/annotation.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/annotation/created.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/annotation/updated.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/build.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/build/canceled.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/build/created.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/build/finished.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/build/received.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/build/received/job.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/build/started.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/build/started/job.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/job.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/job/canceled.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/job/created.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/job/finished.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/job/log.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/job/received.rb",
    "vendor/travis-core/lib/travis/api/v0/pusher/job/started.rb",
    "vendor/travis-core/lib/travis/api/v0/worker.rb",
    "vendor/travis-core/lib/travis/api/v0/worker/job.rb",
    "vendor/travis-core/lib/travis/api/v0/worker/job/test.rb",
    "vendor/travis-core/lib/travis/api/v1.rb",
    "vendor/travis-core/lib/travis/api/v1/archive.rb",
    "vendor/travis-core/lib/travis/api/v1/archive/build.rb",
    "vendor/travis-core/lib/travis/api/v1/archive/build/job.rb",
    "vendor/travis-core/lib/travis/api/v1/helpers.rb",
    "vendor/travis-core/lib/travis/api/v1/helpers/legacy.rb",
    "vendor/travis-core/lib/travis/api/v1/http.rb",
    "vendor/travis-core/lib/travis/api/v1/http/branches.rb",
    "vendor/travis-core/lib/travis/api/v1/http/build.rb",
    "vendor/travis-core/lib/travis/api/v1/http/build/job.rb",
    "vendor/travis-core/lib/travis/api/v1/http/builds.rb",
    "vendor/travis-core/lib/travis/api/v1/http/hooks.rb",
    "vendor/travis-core/lib/travis/api/v1/http/job.rb",
    "vendor/travis-core/lib/travis/api/v1/http/jobs.rb",
    "vendor/travis-core/lib/travis/api/v1/http/repositories.rb",
    "vendor/travis-core/lib/travis/api/v1/http/repository.rb",
    "vendor/travis-core/lib/travis/api/v1/http/user.rb",
    "vendor/travis-core/lib/travis/api/v1/webhook.rb",
    "vendor/travis-core/lib/travis/api/v1/webhook/build.rb",
    "vendor/travis-core/lib/travis/api/v1/webhook/build/finished.rb",
    "vendor/travis-core/lib/travis/api/v1/webhook/build/finished/job.rb",
    "vendor/travis-core/lib/travis/api/v2.rb",
    "vendor/travis-core/lib/travis/chunkifier.rb",
    "vendor/travis-core/lib/travis/commit_command.rb",
    "vendor/travis-core/lib/travis/config/database.rb",
    "vendor/travis-core/lib/travis/config/defaults.rb",
    "vendor/travis-core/lib/travis/config/url.rb",
    "vendor/travis-core/lib/travis/engine.rb",
    "vendor/travis-core/lib/travis/enqueue.rb",
    "vendor/travis-core/lib/travis/enqueue/services.rb",
    "vendor/travis-core/lib/travis/enqueue/services/enqueue_jobs.rb",
    "vendor/travis-core/lib/travis/enqueue/services/enqueue_jobs/limit.rb",
    "vendor/travis-core/lib/travis/errors.rb",
    "vendor/travis-core/lib/travis/event.rb",
    "vendor/travis-core/lib/travis/event/config.rb",
    "vendor/travis-core/lib/travis/event/handler.rb",
    "vendor/travis-core/lib/travis/event/handler/metrics.rb",
    "vendor/travis-core/lib/travis/event/handler/trail.rb",
    "vendor/travis-core/lib/travis/event/subscription.rb",
    "vendor/travis-core/lib/travis/features.rb",
    "vendor/travis-core/lib/travis/github.rb",
    "vendor/travis-core/lib/travis/github/education.rb",
    "vendor/travis-core/lib/travis/github/services.rb",
    "vendor/travis-core/lib/travis/github/services/fetch_config.rb",
    "vendor/travis-core/lib/travis/github/services/find_or_create_org.rb",
    "vendor/travis-core/lib/travis/github/services/find_or_create_repo.rb",
    "vendor/travis-core/lib/travis/github/services/find_or_create_user.rb",
    "vendor/travis-core/lib/travis/github/services/set_hook.rb",
    "vendor/travis-core/lib/travis/github/services/sync_user.rb",
    "vendor/travis-core/lib/travis/github/services/sync_user/organizations.rb",
    "vendor/travis-core/lib/travis/github/services/sync_user/repositories.rb",
    "vendor/travis-core/lib/travis/github/services/sync_user/repository.rb",
    "vendor/travis-core/lib/travis/github/services/sync_user/reset_token.rb",
    "vendor/travis-core/lib/travis/github/services/sync_user/user_info.rb",
    "vendor/travis-core/lib/travis/logs.rb",
    "vendor/travis-core/lib/travis/logs/services.rb",
    "vendor/travis-core/lib/travis/logs/services/aggregate.rb",
    "vendor/travis-core/lib/travis/logs/services/archive.rb",
    "vendor/travis-core/lib/travis/logs/services/receive.rb",
    "vendor/travis-core/lib/travis/mailer.rb",
    "vendor/travis-core/lib/travis/mailer/user_mailer.rb",
    "vendor/travis-core/lib/travis/mailer/views/layouts/contact_email.html.erb",
    "vendor/travis-core/lib/travis/mailer/views/user_mailer/welcome_email.html.erb",
    "vendor/travis-core/lib/travis/model.rb",
    "vendor/travis-core/lib/travis/model/account.rb",
    "vendor/travis-core/lib/travis/model/annotation.rb",
    "vendor/travis-core/lib/travis/model/annotation_provider.rb",
    "vendor/travis-core/lib/travis/model/branch.rb",
    "vendor/travis-core/lib/travis/model/broadcast.rb",
    "vendor/travis-core/lib/travis/model/build.rb",
    "vendor/travis-core/lib/travis/model/build/config.rb",
    "vendor/travis-core/lib/travis/model/build/config/dist.rb",
    "vendor/travis-core/lib/travis/model/build/config/env.rb",
    "vendor/travis-core/lib/travis/model/build/config/features.rb",
    "vendor/travis-core/lib/travis/model/build/config/group.rb",
    "vendor/travis-core/lib/travis/model/build/config/language.rb",
    "vendor/travis-core/lib/travis/model/build/config/matrix.rb",
    "vendor/travis-core/lib/travis/model/build/config/obfuscate.rb",
    "vendor/travis-core/lib/travis/model/build/config/os.rb",
    "vendor/travis-core/lib/travis/model/build/config/yaml.rb",
    "vendor/travis-core/lib/travis/model/build/denormalize.rb",
    "vendor/travis-core/lib/travis/model/build/matrix.rb",
    "vendor/travis-core/lib/travis/model/build/metrics.rb",
    "vendor/travis-core/lib/travis/model/build/result_message.rb",
    "vendor/travis-core/lib/travis/model/build/states.rb",
    "vendor/travis-core/lib/travis/model/build/update_branch.rb",
    "vendor/travis-core/lib/travis/model/commit.rb",
    "vendor/travis-core/lib/travis/model/email.rb",
    "vendor/travis-core/lib/travis/model/encrypted_column.rb",
    "vendor/travis-core/lib/travis/model/env_helpers.rb",
    "vendor/travis-core/lib/travis/model/job.rb",
    "vendor/travis-core/lib/travis/model/job/cleanup.rb",
    "vendor/travis-core/lib/travis/model/job/queue.rb",
    "vendor/travis-core/lib/travis/model/job/test.rb",
    "vendor/travis-core/lib/travis/model/log.rb",
    "vendor/travis-core/lib/travis/model/log/part.rb",
    "vendor/travis-core/lib/travis/model/logs_model.rb",
    "vendor/travis-core/lib/travis/model/membership.rb",
    "vendor/travis-core/lib/travis/model/organization.rb",
    "vendor/travis-core/lib/travis/model/permission.rb",
    "vendor/travis-core/lib/travis/model/repository.rb",
    "vendor/travis-core/lib/travis/model/repository/settings.rb",
    "vendor/travis-core/lib/travis/model/repository/status_image.rb",
    "vendor/travis-core/lib/travis/model/request.rb",
    "vendor/travis-core/lib/travis/model/request/approval.rb",
    "vendor/travis-core/lib/travis/model/request/branches.rb",
    "vendor/travis-core/lib/travis/model/request/pull_request.rb",
    "vendor/travis-core/lib/travis/model/request/states.rb",
    "vendor/travis-core/lib/travis/model/ssl_key.rb",
    "vendor/travis-core/lib/travis/model/token.rb",
    "vendor/travis-core/lib/travis/model/url.rb",
    "vendor/travis-core/lib/travis/model/user.rb",
    "vendor/travis-core/lib/travis/model/user/oauth.rb",
    "vendor/travis-core/lib/travis/model/user/renaming.rb",
    "vendor/travis-core/lib/travis/notification.rb",
    "vendor/travis-core/lib/travis/notification/instrument.rb",
    "vendor/travis-core/lib/travis/notification/instrument/event_handler.rb",
    "vendor/travis-core/lib/travis/notification/instrument/task.rb",
    "vendor/travis-core/lib/travis/notification/publisher.rb",
    "vendor/travis-core/lib/travis/notification/publisher/log.rb",
    "vendor/travis-core/lib/travis/notification/publisher/memory.rb",
    "vendor/travis-core/lib/travis/notification/publisher/redis.rb",
    "vendor/travis-core/lib/travis/overwritable_method_definitions.rb",
    "vendor/travis-core/lib/travis/redis_pool.rb",
    "vendor/travis-core/lib/travis/requests.rb",
    "vendor/travis-core/lib/travis/requests/services.rb",
    "vendor/travis-core/lib/travis/requests/services/receive.rb",
    "vendor/travis-core/lib/travis/requests/services/receive/api.rb",
    "vendor/travis-core/lib/travis/requests/services/receive/cron.rb",
    "vendor/travis-core/lib/travis/requests/services/receive/pull_request.rb",
    "vendor/travis-core/lib/travis/requests/services/receive/push.rb",
    "vendor/travis-core/lib/travis/secure_config.rb",
    "vendor/travis-core/lib/travis/services.rb",
    "vendor/travis-core/lib/travis/services/base.rb",
    "vendor/travis-core/lib/travis/services/cancel_build.rb",
    "vendor/travis-core/lib/travis/services/cancel_job.rb",
    "vendor/travis-core/lib/travis/services/delete_caches.rb",
    "vendor/travis-core/lib/travis/services/find_admin.rb",
    "vendor/travis-core/lib/travis/services/find_annotations.rb",
    "vendor/travis-core/lib/travis/services/find_branch.rb",
    "vendor/travis-core/lib/travis/services/find_branches.rb",
    "vendor/travis-core/lib/travis/services/find_build.rb",
    "vendor/travis-core/lib/travis/services/find_builds.rb",
    "vendor/travis-core/lib/travis/services/find_caches.rb",
    "vendor/travis-core/lib/travis/services/find_daily_repos_stats.rb",
    "vendor/travis-core/lib/travis/services/find_daily_tests_stats.rb",
    "vendor/travis-core/lib/travis/services/find_hooks.rb",
    "vendor/travis-core/lib/travis/services/find_job.rb",
    "vendor/travis-core/lib/travis/services/find_jobs.rb",
    "vendor/travis-core/lib/travis/services/find_log.rb",
    "vendor/travis-core/lib/travis/services/find_repo.rb",
    "vendor/travis-core/lib/travis/services/find_repo_key.rb",
    "vendor/travis-core/lib/travis/services/find_repo_settings.rb",
    "vendor/travis-core/lib/travis/services/find_repos.rb",
    "vendor/travis-core/lib/travis/services/find_request.rb",
    "vendor/travis-core/lib/travis/services/find_requests.rb",
    "vendor/travis-core/lib/travis/services/find_user_accounts.rb",
    "vendor/travis-core/lib/travis/services/find_user_broadcasts.rb",
    "vendor/travis-core/lib/travis/services/find_user_permissions.rb",
    "vendor/travis-core/lib/travis/services/helpers.rb",
    "vendor/travis-core/lib/travis/services/next_build_number.rb",
    "vendor/travis-core/lib/travis/services/regenerate_repo_key.rb",
    "vendor/travis-core/lib/travis/services/registry.rb",
    "vendor/travis-core/lib/travis/services/remove_log.rb",
    "vendor/travis-core/lib/travis/services/reset_model.rb",
    "vendor/travis-core/lib/travis/services/sync_user.rb",
    "vendor/travis-core/lib/travis/services/update_annotation.rb",
    "vendor/travis-core/lib/travis/services/update_hook.rb",
    "vendor/travis-core/lib/travis/services/update_job.rb",
    "vendor/travis-core/lib/travis/services/update_log.rb",
    "vendor/travis-core/lib/travis/services/update_user.rb",
    "vendor/travis-core/lib/travis/settings.rb",
    "vendor/travis-core/lib/travis/settings/collection.rb",
    "vendor/travis-core/lib/travis/settings/encrypted_value.rb",
    "vendor/travis-core/lib/travis/settings/model.rb",
    "vendor/travis-core/lib/travis/settings/model_extensions.rb",
    "vendor/travis-core/lib/travis/states_cache.rb",
    "vendor/travis-core/lib/travis/task.rb",
    "vendor/travis-core/lib/travis/testing.rb",
    "vendor/travis-core/lib/travis/testing/factories.rb",
    "vendor/travis-core/lib/travis/testing/matchers.rb",
    "vendor/travis-core/lib/travis/testing/payloads.rb",
    "vendor/travis-core/lib/travis/testing/scenario.rb",
    "vendor/travis-core/lib/travis/testing/stubs.rb",
    "vendor/travis-core/lib/travis/testing/stubs/stub.rb",
    "vendor/travis-core/lib/travis/travis_yml_stats.rb",
    "vendor/travis-core/lib/travis_core/version.rb",
    "vendor/travis-core/travis-core.gemspec"
  ]

  s.add_dependency 'travis-support'
  s.add_dependency 'travis-core'

  s.add_dependency 'pg'
  s.add_dependency 'composite_primary_keys', '~> 5.0'
  s.add_dependency 'sinatra',                '~> 1.3'
  s.add_dependency 'sinatra-contrib',        '~> 1.3'
  s.add_dependency 'mustermann',             '~> 0.4'
  s.add_dependency 'redcarpet',              '~> 2.1'
  s.add_dependency 'rack-ssl',               '~> 1.3', '>= 1.3.3'
  s.add_dependency 'rack-contrib',           '~> 1.1'
  s.add_dependency 'memcachier'
  s.add_dependency 'useragent'
end

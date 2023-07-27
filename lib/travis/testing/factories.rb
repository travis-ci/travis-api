require 'factory_bot'

FactoryBot.define do

  factory :build, class: Build do
    owner { User.first || FactoryBot.create(:user) }
    owner_type { 'User' }
    repository { Repository.first || FactoryBot.create(:repository_without_last_build) }
    association :request
    association :commit
    started_at { Time.now.utc }
    finished_at { Time.now.utc }
    sequence(:number) {|n| n }
    state { :passed }
    private { false }
  end

  factory :build_backup, class: BuildBackup do
    repository { Repository.first || FactoryBot.create(:repository_without_last_build) }
    sequence(:file_name) { |n| "repository_builds_#{n}-#{n + 100}" }
  end

  factory :commit, class: Commit do
    commit { '62aae5f70ceee39123ef' }
    branch { 'master' }
    message { 'the commit message 🤔' }
    committed_at { '2011-11-11T11:11:11Z' }
    committer_name { 'Sven Fuchs' }
    committer_email { 'svenfuchs@artweb-design.de' }
    author_name { 'Sven Fuchs' }
    author_email { 'svenfuchs@artweb-design.de' }
    compare_url { 'https://github.com/svenfuchs/minimal/compare/master...develop' }
  end

  factory :subscription do
    association :owner, factory: :user
    valid_to { Time.now.utc + 1.week }
    customer_id { 'cus_123' }
    billing_email { 'shairyar@travis-ci.org' }
    cc_last_digits { 111 }
    status { 'subscribed'}
    source { 'stripe' }
    cc_token { 'token_123' }
    selected_plan { 'travis-ci-one-build' }
    country { 'Germany' }

    factory :valid_stripe_subs do
      status { 'subscribed' }
      source { 'stripe' }
    end

    factory :canceled_stripe_subs do
      status { 'canceled' }
      source { 'stripe' }
    end
  end

  factory :test, :class => 'Job::Test', aliases: [:job] do
    owner      { User.first || FactoryBot.create(:user) }
    owner_type { 'User' }
    repository { Repository.first || FactoryBot.create(:repository) }
    commit     { FactoryBot.create(:commit) }
    source     { FactoryBot.create(:build) }
    source_type { 'Build' }
    config     { { 'rvm' => '1.8.7', 'gemfile' => 'test/Gemfile.rails-2.3.x' } }
    number     { '2.1' }
    tags       { "" }
    state      { :created }
    private    { false }
  end

  factory :request do
    repository { Repository.first || FactoryBot.create(:repository) }
    association :commit
    token { 'the-token' }
    event_type { 'push' }
    private { false }
  end

  factory :url, class: Url do
    name { 'http://travis-ci.com' }
  end

  factory :repository_without_last_build, class: Repository do
   # owner { User.find_by_login('svenfuchs') || FactoryBot.create(:user) }
    name { 'minimal' }
    owner_name { 'svenfuchs' }
    owner_email { 'svenfuchs@artweb-design.de' }
    active { true }
    url { |r| "http://github.com/#{r.owner_name}/#{r.name}" }
    created_at { |r| Time.utc(2011, 01, 30, 5, 25) }
    updated_at { |r| r.created_at + 5.minutes }
    last_build_state { :passed }
    last_build_number { '2' }
    last_build_started_at { Time.now.utc }
    last_build_finished_at { Time.now.utc }
    sequence(:github_id) {|n| n }
    private { false }

    transient do
      owner { User.first || FactoryBot.create(:user) }
    end
    owner_id {owner.id}
    owner_type {owner.class.name}

  end

  factory :repository, :parent => :repository_without_last_build do
    after(:create) do |repo|
      repo.last_build ||= FactoryBot.create(:build, repository: repo)
    end
  end

  factory :v3_repository, class: Travis::API::V3::Models::Repository do
  end

  factory :minimal, :parent => :repository_without_last_build do
  end

  factory :enginex, :parent => :repository_without_last_build do
    name { 'enginex' }
    owner_name { 'josevalim' }
    owner_type { 'User' }
    owner_email { 'josevalim@email.example.com' }
    owner { User.find_by_login('josevalim') || FactoryBot.create(:user, :login => 'josevalim') }
  end

  factory :sharedrepo, :parent => :repository_without_last_build do
    name { 'sharedrepo' }
    owner_name { 'sharedrepoowner' }
    owner_type { 'User' }
    owner_email { 'sharedrepo@owner.email.com' }
    owner { User.find_by_login('sharedrepoowner') || FactoryBot.create(:user, :login => 'sharedrepoowner', :name => 'Sharedrepo Owner') }
    last_build_number { nil }
    last_build_started_at { nil }
    last_build_finished_at { nil }
  end

  factory :event do
    repository { Repository.first || FactoryBot.create(:repository) }
    source { Build.first || FactoryBot.create(:build) }
    event { 'build:started' }
  end

  factory :permission do
  end

  factory :sharedrepo_permission, class: Permission do
    user_id { (User.find_by_login('johndoe') || FactoryBot.create(:user_with_sharedrepo)).id }
    repository_id { Repository.find_by_name('sharedrepo').id }
    admin { false }
    push { true }
    pull { true }
  end

  factory :membership, class: Travis::API::V3::Models::Membership do
    organization_id { FactoryBot.create(:org_v3).id }
    user_id         { FactoryBot.create(:user).id }
    role         { "admin" }
  end

  factory :user do
    name  { 'Sven Fuchs' }
    login { 'svenfuchs' }
    email { 'sven@fuchs.com' }
    tokens { [Token.new] }
    github_oauth_token { 'github_oauth_token' }
  end

  factory :user_with_sharedrepo, class: User do
    name  { 'John Doe' }
    login { 'johndoe' }
    email { 'john@doe.internet' }
    tokens { [Token.new] }
    github_oauth_token { 'github_oauth_token' }
  end

  factory :org_v3, class: Travis::API::V3::Models::Organization do
    name { 'travis-ci' }
    login { 'travis-ci' }
  end

  factory :running_build, :parent => :build, class: Build do
    repository { FactoryBot.create(:repository, :name => 'running_build') }
    state { :started }
  end

  factory :successful_build, :parent => :build, class: Build do
    repository { |b| FactoryBot.create(:repository, :name => 'successful_build') }
    state { :passed }
    started_at { Time.now.utc }
    finished_at { Time.now.utc }
  end

  factory :broken_build, :parent => :build, class: Build do
    repository { FactoryBot.create(:repository, :name => 'broken_build', :last_build_state => :failed) }
    state { :failed }
    started_at { Time.now.utc }
    finished_at { Time.now.utc }
  end

  factory :broken_build_with_tags, :parent => :build, class: Build do
    repository  { FactoryBot.create(:repository, :name => 'broken_build_with_tags', :last_build_state => :errored) }
    matrix      {[FactoryBot.create(:test, :owner_type => 'User', :tags => "database_missing,rake_not_bundled",   :number => "1.1"),
                  FactoryBot.create(:test, :owner_type => 'User', :tags => "database_missing,log_limit_exceeded", :number => "1.2")]}
    state       { :failed }
    started_at  { Time.now.utc }
    finished_at { Time.now.utc }
  end

  factory :branch, class: Travis::API::V3::Models::Branch do
    name { Random.rand(1..1000) }
    repository_id { FactoryBot.create(:repository).id }
    association :repository
  end

  factory :v3_build, class: Travis::API::V3::Models::Build do
    owner { User.first || FactoryBot.create(:user) }
    owner_type { 'User' }
    repository { Repository.first || FactoryBot.create(:repository) }
    association :request
    association :commit
    started_at { Time.now.utc }
    finished_at { Time.now.utc }
    sequence(:number) {|n| n }
    state { :passed }
  end

  factory :cron, class: Travis::API::V3::Models::Cron do
    branch { FactoryBot.create(:branch) }
    interval { "daily" }
    dont_run_if_recent_build_exists { false }
    active { true }
  end

  factory :org, class: Organization do
    name { 'travis-ci' }
    login { 'travis-ci' }
  end

  factory :beta_migration_request, class: Travis::API::V3::Models::BetaMigrationRequest do
    owner_id { FactoryBot.create(:user, :login => 'dummy_user').id }
    owner_name { 'dummy_user' }
    owner_type { 'User' }
    accepted_at { nil }
  end
end

require 'factory_girl'

FactoryGirl.define do
  factory :user do
    name  'Sven Fuchs'
    login 'svenfuchs'
    email 'sven@fuchs.com'
    tokens { [Token.new] }
    github_oauth_token { SecureRandom.base64 }
  end

  factory :repository do
    owner { User.find_by_login('svenfuchs') || Factory(:user) }
    name 'minimal'
    owner_name 'svenfuchs'
    owner_email 'svenfuchs@artweb-design.de'
    active true
    url { |r| "http://github.com/#{r.owner_name}/#{r.name}" }
    created_at { |r| Time.utc(2011, 01, 30, 5, 25) }
    updated_at { |r| r.created_at + 5.minutes }
    last_build_state :passed
    last_build_number '2'
    last_build_id 2
    last_build_started_at { Time.now.utc }
    last_build_finished_at { Time.now.utc }
    sequence(:github_id) {|n| n }
  end

  factory :branch, class: Travis::API::V3::Models::Branch do
    sequence(:name) { |n| n }
    repository_id { (Repository.find_by_name('minimal') || Factory(:repository)).id }
  end

  factory :cron, class: Travis::API::V3::Models::Cron do
    branch { Factory(:branch) }
    interval "daily"
    dont_run_if_recent_build_exists false
  end

  factory :v3_build, class: Travis::API::V3::Models::Build do
    owner { User.first || Factory(:user) }
    repository { Repository.first || Factory(:repository) }
    association :request
    association :commit
    started_at { Time.now.utc }
    finished_at { Time.now.utc }
    number 1
    state :passed
  end

  factory :request do
    repository { Repository.first || Factory(:repository) }
    association :commit
    token 'the-token'
    event_type 'push'
  end

  factory :commit do
    commit '62aae5f70ceee39123ef'
    branch_name 'master'
    message 'the commit message 🤔'
    committed_at '2011-11-11T11:11:11Z'
    committer_name 'Sven Fuchs'
    committer_email 'svenfuchs@artweb-design.de'
    author_name 'Sven Fuchs'
    author_email 'svenfuchs@artweb-design.de'
    compare_url 'https://github.com/svenfuchs/minimal/compare/master...develop'
  end

  factory :build do
    owner { User.first || Factory(:user) }
    repository { Repository.first || Factory(:repository) }
    association :request
    association :commit
    started_at { Time.now.utc }
    finished_at { Time.now.utc }
    number 1
    state :passed
  end
#
#   factory :test, :class => 'Job::Test' do
#     owner      { User.first || Factory(:user) }
#     repository { Repository.first || Factory(:repository) }
#     commit     { Factory(:commit) }
#     source     { Factory(:build) }
#     log        { Factory(:log) }
#     config     { { 'rvm' => '1.8.7', 'gemfile' => 'test/Gemfile.rails-2.3.x' } }
#     number     '2.1'
#     tags       ""
#   end
#
#   factory :log do
#     content '$ bundle install --pa'
#   end
#
#   factory :request do
#     repository { Repository.first || Factory(:repository) }
#     association :commit
#     token 'the-token'
#     event_type 'push'
#   end
#

#
#   factory :minimal, :parent => :repository do
#   end
#
#   factory :enginex, :parent => :repository do
#     name 'enginex'
#     owner_name 'josevalim'
#     owner_email 'josevalim@email.com'
#     owner { User.find_by_login('josevalim') || Factory(:user, :login => 'josevalim') }
#   end
#
#   factory :event do
#     repository { Repository.first || Factory(:repository) }
#     source { Build.first || Factory(:build) }
#     event 'build:started'
#   end
#

#
#   factory :org, :class => 'Organization' do
#     name 'travis-ci'
#   end
#
#   factory :running_build, :parent => :build do
#     repository { Factory(:repository, :name => 'running_build') }
#     state :started
#   end
#
#   factory :successful_build, :parent => :build do
#     repository { |b| Factory(:repository, :name => 'successful_build') }
#     state :passed
#     started_at { Time.now.utc }
#     finished_at { Time.now.utc }
#   end
#
#   factory :broken_build, :parent => :build do
#     repository { Factory(:repository, :name => 'broken_build', :last_build_state => :failed) }
#     state :failed
#     started_at { Time.now.utc }
#     finished_at { Time.now.utc }
#   end
#
#   factory :broken_build_with_tags, :parent => :build do
#     repository  { Factory(:repository, :name => 'broken_build_with_tags', :last_build_state => :errored) }
#     matrix      {[Factory(:test, :tags => "database_missing,rake_not_bundled",   :number => "1.1"),
#                   Factory(:test, :tags => "database_missing,log_limit_exceeded", :number => "1.2")]}
#     state       :failed
#     started_at  { Time.now.utc }
#     finished_at { Time.now.utc }
#   end
#
#   factory :annotation do
#     url "https://travis-ci.org/travis-ci/travis-ci/jobs/12345"
#     description "Job passed"
#     job { Factory(:test) }
#     annotation_provider { Factory(:annotation_provider) }
#   end
#
#   factory :annotation_provider do
#     name "Travis CI"
#     api_username "travis-ci"
#     api_key "0123456789abcdef"
#   end
#
#
#   factory :v3_build, class: Travis::API::V3::Models::Build do
#     owner { User.first || Factory(:user) }
#     repository { Repository.first || Factory(:repository) }
#     association :request
#     association :commit
#     started_at { Time.now.utc }
#     finished_at { Time.now.utc }
#     number 1
#     state :passed
#   end
#
#   factory :cron, class: Travis::API::V3::Models::Cron do
#     branch { Factory(:branch) }
#     interval "daily"
#     dont_run_if_recent_build_exists false
#   end
end

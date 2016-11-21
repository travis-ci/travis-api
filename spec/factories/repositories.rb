FactoryGirl.define do
  factory :repository do
    name 'travis-admin'
    association :owner, factory: :organization
    owner_name 'travis-pro'
    description 'test'
    default_branch 'master'

    trait :inactive do
      active false
    end

    factory :repository_with_last_build do
      last_build_id 123
      last_build_number '4'
      last_build_started_at '2016-11-10 19:36:00 UTC'
      last_build_finished_at '2016-11-10 19:39:00 UTC'
      last_build_duration 180
      last_build_state 'passed'

      after(:create) do |repo|
        create(:build, id: repo.last_build_id,
                       number: repo.last_build_number,
                       state: repo.last_build_state,
                       started_at: repo.last_build_started_at,
                       finished_at: repo.last_build_finished_at,
                       duration: repo.last_build_duration)
      end
    end

    factory :repo_with_users do
      after(:create) do |repo|
        create(:permission, repository: repo, admin: true)
        create(:permission, repository: repo, pull: true)
        create(:permission, repository: repo, push: true)
      end
    end

    factory :inactive_repository, traits: [:inactive]
  end
end

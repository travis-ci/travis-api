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

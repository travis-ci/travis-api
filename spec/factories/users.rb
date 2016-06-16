FactoryGirl.define do
  factory :user do
    login 'sinthetix'
    email 'aly@example.com'

    factory :user_with_organizations do
      transient do
        organization_count 2
      end

      after(:create) do |user, evaluator|
        create_list(:organization, evaluator.organization_count, users: [user])
      end
    end

    factory :user_with_repository do
      after(:create) do |user|
        repo = create(:repository, owner: user)
        create(:permission, repository_id: repo.id, user_id: user.id )
      end
    end

    factory :user_with_repositories do
      transient do
        repository_count 2
      end

      after(:create) do |user, evaluator|
        create_list(:repository, evaluator.repository_count, owner: user)
      end
    end

    factory :user_with_repo_through_organization do
      after(:create) do |user|
        organization = create(:organization, users: [user])
        repo = create(:repository, owner: organization, name: 'emerald')
        create(:permission, repository_id: repo.id, user_id: user.id)
      end
    end

    trait :with_subscription do
      after(:create) do |user|
        user.subscription = create(:subscription)
      end
    end
  end
end

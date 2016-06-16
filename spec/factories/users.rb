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

    factory :user_with_repositories do
      transient do
        repository_count 2
      end

      after(:create) do |user, evaluator|
        create_list(:repository, evaluator.repository_count, owner: user)
      end
    end

    trait :with_subscription do
      after(:create) do |user|
        user.subscription = create(:subscription)
      end
    end
  end
end

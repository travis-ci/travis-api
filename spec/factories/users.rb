FactoryGirl.define do
  factory :user do
    login 'sinthetix'
    email 'aly@example.com'
  end

  trait :with_organization do
    after(:create) do |user|
      user.organizations << create(:organization)
    end
  end

  trait :with_repo do
    after(:create) do |user|
      user.repositories << create(:repository)
    end
  end

  trait :with_subscription do
    after(:create) do |user|
      user.subscription = create(:subscription)
    end
  end
end

FactoryGirl.define do
  factory :subscription do
    association :owner, factory: :user

    trait :active do
      cc_token 'kbfse87t3'
      valid_to { 1.week.from_now }
      selected_plan 'travis-ci-twenty-builds-annual'
    end

    trait :expired do
      valid_to { 1.week.ago }
    end

    factory :active_subscription, traits: [:active]
    factory :expired_subscription, traits: [:expired]
  end
end

FactoryGirl.define do
  factory :subscription do
    association :owner, factory: :user
    billing_email 'contact@travis-ci.com'
    vat_id 'DE999999999'

    trait :active do
      cc_token 'kbfse87t3'
      valid_to { 1.week.from_now }
      selected_plan 'travis-ci-twenty-builds-annual'

      after(:create) do |subscription|
        create(:plan, subscription: subscription, updated_at: 1.week.ago)
        create(:plan, subscription: subscription, updated_at: 1.year.ago)
      end
    end

    trait :expired do
      valid_to { 1.week.ago }
    end

    factory :active_subscription, traits: [:active]
    factory :expired_subscription, traits: [:expired]
  end
end

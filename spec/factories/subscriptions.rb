FactoryGirl.define do
  factory :subscription do
    association :owner, factory: :user
    billing_email 'contact@travis-ci.com'
    vat_id 'DE999999999'

    trait :active do
      valid_to { 1.week.from_now }
      selected_plan 'travis-ci-twenty-builds-annual'
      first_name 'Katrin'
      last_name 'Mustermann'
      company 'Travis CI'
      country 'Germany'
      address 'Nice Street 12'
      city 'Berlin'
      zip_code '12344'

      after(:create) do |subscription|
        create(:plan, subscription: subscription, updated_at: 1.week.ago)
        create(:plan, subscription: subscription, updated_at: 1.year.ago)
      end
    end

    trait :expired do
      valid_to { 1.week.ago }
    end

    trait :has_token do
      cc_token 'tok_1076247Biz'
    end

    factory :active_subscription, traits: [:active, :has_token]
    factory :expired_subscription, traits: [:expired, :has_token]
    factory :subscription_missing_token, traits: [:active]
  end
end

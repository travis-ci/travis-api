FactoryGirl.define do
  factory :subscription do
    association :owner, factory: :user
    billing_email 'contact@travis-ci.com'
    vat_id 'DE999999999'
    selected_plan 'travis-ci-twenty-builds-annual'
		country 'Germany'

    trait :active do
      valid_to { 1.week.from_now }
      first_name 'Katrin'
      last_name 'Mustermann'
      company 'Travis CI'
      address 'Nice Street 12'
      city 'Berlin'
      zip_code '12344'
			customer_id 'cus_123'
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

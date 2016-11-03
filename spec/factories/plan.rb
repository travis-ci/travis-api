FactoryGirl.define do
  factory :plan do
    subscription
    updated_at 1.week.ago
    amount 249
    name 'travis-ci-five-builds'
  end
end

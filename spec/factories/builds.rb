FactoryGirl.define do
  factory :build do
    association :owner, factory: :organization
    repository
    commit
    number "456"
  end
end

FactoryGirl.define do
  factory :job do
    association :owner, factory: :organization
    repository
    commit
    number "123"
  end
end

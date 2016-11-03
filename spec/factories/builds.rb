FactoryGirl.define do
  factory :build do
    association :owner, factory: :organization
    repository
    commit
    number '123'
    started_at '2016-06-29 11:06:01'

    trait :started do
      finished_at nil
      state 'started'
    end

    trait :finished do
      finished_at '2016-06-29 11:09:09'
    end

    trait :failed do
       state 'failed'
    end

    factory :started_build, traits: [:started]
    factory :failed_build, traits: [:finished, :failed]
  end
end

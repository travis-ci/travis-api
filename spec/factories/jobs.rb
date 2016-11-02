FactoryGirl.define do
  factory :job do
    association :owner, factory: :organization
    build
    repository
    commit
    number '123.4'
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

    factory :started_job, traits: [:started]
    factory :failed_job, traits: [:finished, :failed]
  end
end

FactoryGirl.define do
  factory :job do
    association :owner, factory: :organization
    build
    repository
    commit
    started_at '2016-06-29 11:06:01'
    number '123.4'


    trait :received do
      state 'received'
      started_at nil
    end

    trait :created do
      state 'created'
      started_at nil
    end

    trait :queued do
      state 'queued'
      started_at nil
    end

    trait :started do
      state 'started'
    end

    trait :finished do
      finished_at '2016-06-29 11:09:09'
    end

    trait :failed do
      state 'failed'
    end

    trait :passed do
      state 'passed'
    end

    trait :canceled do
      state 'canceled'
    end

    trait :errored do
      state 'errored'
    end

    factory :received_job, traits: [:received]
    factory :created_job, traits: [:created]
    factory :queued_job, traits: [:queued]
    factory :started_job, traits: [:started]
    factory :finished_job, traits: [:finished]
    factory :failed_job, traits: [:finished, :failed]
    factory :passed_job, traits: [:finished, :passed]
    factory :canceled_job, traits: [:finished, :canceled]
    factory :errored_job, traits: [:finished, :errored]
  end
end

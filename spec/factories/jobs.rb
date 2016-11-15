FactoryGirl.define do
  factory :job do
    association :owner, factory: :organization
    source_type 'Build'
    build
    repository
    commit
    created_at  '2016-06-29 11:04:01 UTC'
    queued_at   '2016-06-29 11:05:01 UTC'
    received_at '2016-06-29 11:06:01 UTC'
    started_at  '2016-06-29 11:07:01 UTC'
    number '123.4'

    trait :created do
      state 'created'
      started_at  nil
      received_at nil
      queued_at   nil
    end

    trait :queued do
      state 'queued'
      started_at  nil
      received_at nil
    end

    trait :received do
      state 'received'
      started_at  nil
    end

    trait :started do
      state 'started'
    end

    trait :finished do
      finished_at '2016-06-29 11:09:09 UTC'
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

    factory :created_job,  traits: [:created]
    factory :queued_job,   traits: [:queued]
    factory :received_job, traits: [:received]
    factory :started_job,  traits: [:started]
    factory :finished_job, traits: [:finished]
    factory :failed_job,   traits: [:finished, :failed]
    factory :passed_job,   traits: [:finished, :passed]
    factory :canceled_job, traits: [:finished, :canceled]
    factory :errored_job,  traits: [:finished, :errored]
  end
end

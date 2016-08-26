FactoryGirl.define do
  factory :organization do
    name 'Travis'
    login 'travis-pro'

    factory :organization_with_repositories do
      transient do
        repo_count 2
      end

      after(:create) do |organization, evaluator|
        create_list(:repository, evaluator.repo_count, owner: organization)
      end
    end
  end
end

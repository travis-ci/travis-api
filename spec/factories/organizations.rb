FactoryGirl.define do
  factory :organization do
    name 'Travis'
    login 'travis-pro'
    preferences JSON.load('{}')

    factory :organization_with_abuse do
      transient do
        level 0
      end

      after(:create) do |organization, evaluator|
        create(:abuse, owner_id: organization.id, level: evaluator.level, owner_type: 'Organization')
      end
    end

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
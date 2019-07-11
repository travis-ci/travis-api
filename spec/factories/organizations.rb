FactoryGirl.define do
  factory :organization do
    name 'Travis'
    login 'travis-pro'

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

    factory :organization_with_github_id do
      github_id 123
    end

    factory :organization_with_ghid_repo do
      github_id 124

      transient do
        repo_count 1
      end

      after(:create) do |organization, evaluator|
        create_list(:repository, evaluator.repo_count, owner: organization)
      end
    end
  end
end

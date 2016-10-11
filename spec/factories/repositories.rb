FactoryGirl.define do
  factory :repository do
    name 'travis-admin'
    owner_name 'travis-pro'

    factory :repo_with_users do
      after(:create) do |repo|
        create(:permission, repository: repo, admin: true)
        create(:permission, repository: repo, pull: true)
        create(:permission, repository: repo, push: true)
      end
    end
  end
end

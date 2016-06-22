FactoryGirl.define do
  factory :repository do
    name 'travis-admin'

    factory :repo_with_users do
      after(:create) do |repo|
        user_admin = create(:user)
        user_pull = create(:user)
        user_push = create(:user)

        create(:permission, repository_id: repo.id, user_id: user_admin.id, admin: true)
        create(:permission, repository_id: repo.id, user_id: user_pull.id, pull: true)
        create(:permission, repository_id: repo.id, user_id: user_push.id, push: true)
      end
    end
  end
end

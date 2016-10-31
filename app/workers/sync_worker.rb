class SyncWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'admin-v2'

  def perform(user_id)
    user = User.find(user_id)
    Services::User::Sync.new(user).call
  end
end

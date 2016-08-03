class SyncWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'admin-v2'

  def perform(user_id)
    Services::User::Sync.new(user_id).call
  end
end

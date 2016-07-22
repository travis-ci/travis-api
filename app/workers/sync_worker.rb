class SyncWorker
  include Sidekiq::Worker

  def perform(user_id)
    Services::User::Sync.new(user_id).call
  end
end

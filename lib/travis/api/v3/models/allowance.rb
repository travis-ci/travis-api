module Travis::API::V3
  class Models::Allowance
    attr_reader :subscription_type, :public_repos, :private_repos, :concurrency_limit, :user_usage, :pending_user_licenses, :id,
                :payment_changes_block_credit, :payment_changes_block_captcha, :credit_card_block_duration, :captcha_block_duration

    def initialize(subscription_type, owner_id, attributes = {})
      @subscription_type = subscription_type
      @id = owner_id
      @subscription_type = 3 if !!attributes['no_plan']
      @public_repos = attributes.fetch('public_repos', nil)
      @private_repos = attributes.fetch('private_repos', nil)
      @concurrency_limit = attributes.fetch('concurrency_limit', nil)
      @user_usage = attributes.fetch('user_usage', nil)
      @pending_user_licenses = attributes.fetch('pending_user_licenses', nil)
      @payment_changes_block_captcha = attributes.fetch('payment_changes_block_captcha', nil)
      @payment_changes_block_credit = attributes.fetch('payment_changes_block_credit', nil)
      @credit_card_block_duration = attributes.fetch('credit_card_block_duration', nil)
      @captcha_block_duration = attributes.fetch('captcha_block_duration', nil)
    end
  end
end

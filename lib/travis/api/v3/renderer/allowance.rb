module Travis::API::V3
  class Renderer::Allowance < ModelRenderer
    representation(:minimal, :id)
    representation(:standard, :subscription_type, :public_repos, :private_repos, :concurrency_limit, :user_usage, :pending_user_licenses,
                   :payment_changes_block_credit, :payment_changes_block_captcha, :credit_card_block_duration, :captcha_block_duration, :id)
  end
end

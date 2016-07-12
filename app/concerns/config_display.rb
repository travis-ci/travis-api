module ConfigDisplay
  extend ActiveSupport::Concern

  def configuration
    config.except(:".result")
  end

  def config_result
    config[:".result"]
  end
end

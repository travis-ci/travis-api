module ConfigDisplay
  extend ActiveSupport::Concern

  def configuration
    config.except(:".result")
  end
end

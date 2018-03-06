class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def travis_config
    Rails.configuration.travis_config
  end
end

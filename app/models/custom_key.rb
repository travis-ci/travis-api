class CustomKey < ActiveRecord::Base
  def added_by_login
    added_by.nil? ? '' : User.find(added_by).login
  end
end

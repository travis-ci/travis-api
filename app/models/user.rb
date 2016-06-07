class User < ActiveRecord::Base
  has_many :emails
end

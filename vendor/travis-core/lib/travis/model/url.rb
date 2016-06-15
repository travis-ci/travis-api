require 'digest/sha1'
require 'travis/model'

class Url < Travis::Model
  validates :url,  :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true

  before_validation :set_code, :on => :create

  def self.shorten(url)
    find_or_create_by_url(url)
  end

  def short_url
    ["http://#{Travis.config.shorten_host}", code].join('/')
  end

  private

  def set_code
    self.code = Digest::SHA1.hexdigest(url)[0..9]
  end
end

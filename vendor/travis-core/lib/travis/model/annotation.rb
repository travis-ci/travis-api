require "active_record"
require "addressable/uri"
require 'travis/event'

class Annotation < ActiveRecord::Base
  include Travis::Event

  belongs_to :job
  belongs_to :annotation_provider

  attr_accessible :description, :url, :job_id, :status

  validates :job_id, presence: true
  validates :description, presence: true
  validate :validate_url_scheme

  private
  def validate_url_scheme
    return unless self.url

    uri = Addressable::URI.parse(self.url)
    unless %w[http https].include?(uri.scheme)
      errors.add(:url, 'URL must use http or https scheme')
    end
  rescue Addressable::URI::InvalidURIError
    errors.add(:url, 'URL is invalid')
  end
end

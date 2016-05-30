require 'active_record'
require 'travis/model/encrypted_column'

class AnnotationProvider < ActiveRecord::Base
  has_many :annotations

  serialize :api_key, Travis::Model::EncryptedColumn.new

  def self.authenticate_provider(username, key)
    provider = where(api_username: username).first

    return unless provider && provider.api_key == key

    provider
  end

  def annotation_for_job(job_id)
    annotations.where(job_id: job_id).first || annotations.build(job_id: job_id)
  end
end

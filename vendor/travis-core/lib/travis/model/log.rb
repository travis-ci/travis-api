require 'metriks'
require 'active_support/core_ext/string/filters'
require 'travis/model'

class Log < Travis::LogsModel
  require 'travis/model/log/part'

  AGGREGATE_PARTS_SELECT_SQL = <<-sql.squish
    SELECT array_to_string(array_agg(log_parts.content ORDER BY number, id), '')
      FROM log_parts
     WHERE log_id = ?
  sql

  class << self
    def aggregated_content(id)
      Metriks.timer('logs.read_aggregated').time do
        connection.select_value(sanitize_sql([AGGREGATE_PARTS_SELECT_SQL, id])) || ''
      end
    end
  end

  include Travis::Event

  belongs_to :job
  belongs_to :removed_by, class_name: 'User', foreign_key: :removed_by
  has_many :parts, class_name: 'Log::Part', foreign_key: :log_id, :dependent => :destroy

  def content
    content = read_attribute(:content) || ''
    content = [content, self.class.aggregated_content(id)].join unless aggregated?
    content
  end

  def aggregated?
    !!aggregated_at
  end

  def clear!
    update_column(:content, '')        # TODO why in the world does update_attributes not set content to ''
    update_column(:aggregated_at, nil) # TODO why in the world does update_attributes not set aggregated_at to nil?
    update_column(:archived_at, nil)
    update_column(:archive_verified, nil)
    Log::Part.where(log_id: id).delete_all
    parts.reload
  end

  def archived?
    archived_at && archive_verified?
  end

  def to_json
    { 'log' => attributes.slice(*%w(id content created_at job_id updated_at)) }.to_json
  end
end

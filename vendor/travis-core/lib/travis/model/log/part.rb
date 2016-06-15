class Log::Part < Travis::LogsModel
  self.table_name = 'log_parts'

  validates :log_id, presence: true, numericality: { greater_than: 0 }
end

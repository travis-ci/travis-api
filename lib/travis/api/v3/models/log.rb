module Travis::API::V3
  class Models::Log < Model
    establish_connection(Travis.config.logs_database)
    belongs_to :job
    belongs_to :removed_by, class_name: 'User', foreign_key: :removed_by
    has_many  :log_parts, dependent: :destroy
  end
end

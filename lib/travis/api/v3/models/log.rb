module Travis::API::V3
  class Models::Log < LogsModel
    belongs_to :job
    belongs_to :removed_by, class_name: 'User', foreign_key: :removed_by
    has_many  :log_parts, dependent: :destroy, order: 'number ASC'

    def clear!(user)
      removed_at = Time.now.utc
      message ="Log removed by #{user.name} at #{removed_at}"
      update_attributes!(
        :content => nil,
        :aggregated_at => nil,
        :archived_at => nil,
        :removed_at => removed_at,
        :removed_by => user
      )
      log_parts.destroy_all
      log_parts.create(content: message, number: 1, final: true)
    end

    def archived?
      archived_at && archive_verified?
    end
  end
end

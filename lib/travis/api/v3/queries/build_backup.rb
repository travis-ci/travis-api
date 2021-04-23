module Travis::API::V3
  class Queries::BuildBackup < RemoteQuery
    params :id

    def find
      raise WrongParams, 'missing build_backup.id'.freeze unless id
      build_backup = Models::BuildBackup.find_by_id(id)
      content = get(build_backup.file_name)
      raise EntityMissing, 'could not retrieve content'.freeze if content.nil?
      build_backup.content = content.force_encoding('UTF-8') if content.present?

      build_backup
    end

    private

    def main_type
      'build_backup'
    end
  end
end

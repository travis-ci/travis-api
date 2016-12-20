class ArchivedBuild < Build

  def self.archive_old_builds
    # for the initial population of the archive table this will not work as it will be waaay to much data to run through Ruby
    Build.where("created_at < CURRENT_DATE - INTERVAL '3 months'").each do |build|
      build.destroy if ArchivedBuild.create(build.attributes)
    end
  end
end

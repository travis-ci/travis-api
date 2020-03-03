class Build
  class UpdateBranch < Struct.new(:build)
    MSGS = {
      update: 'Setting last_build_id to %s on branch %s, repo %s',
      kaputt: 'Inconsistent branch.last_build_id=%s on branch: %s (repo: %s). Should be: %s.'
    }

    def update_last_build
      logger.info MSGS[:update] % [build.id, branch_name, repository.slug]
      branch.update!(last_build_id: build.id)
      validate_branch_last_build_id # TODO double check and remove after a few days
    end

    private

      def validate_branch_last_build_id
        return if branch.reload.last_build_id == build.id
        logger.warn MSGS[:kaputt] % [branch.last_build_id, branch_name, repository.slug, build.id]
      end

      def branch
        Branch.where(repository_id: repository.id, name: branch_name).first_or_create
      end

      def branch_name
        build.branch || 'master'
      end

      def repository
        build.repository
      end

      def logger
        Travis.logger
      end
  end
end

namespace :build do
  namespace :migrate do
    task :branch do
      require 'travis'
      Travis::Database.connect


      Build.select(['id', 'commit_id']).pushes.includes(:commit).find_in_batches do |builds|
        branches = Hash.new { |h, k| h[k] = [] }

        builds.each do |build|
          #next if build.branch
          branches[build.commit.branch] << build.id
        end

        branches.each do |branch, ids|
          Build.where(id: ids).update_all(branch: branch)
        end
      end; nil

    end
  end
end

namespace :build do
  namespace :migrate do
    task :branch do
      require 'travis'
      Travis::Database.connect

      branches = Hash.new { |h, k| h[k] = [] }

      Build.pushes.includes(:commit).find_in_batches do |builds|
        builds.each do |build|
          #next if build.branch
          branches[build.commit.branch] << build.id
        end
      end

      branches.each do |branch, ids|
        Build.where(id: ids).update_all(branch: branch)
      end
    end
  end
end

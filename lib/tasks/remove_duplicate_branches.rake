$: << 'lib'
=begin
Problem: we have duplicate branch records
Problem: we reference branches across 4 tables

If we delete duplicates, we run the risk of break fk references in other tables,
possibly/likely resulting in application-level errors:

API wants to fetch a build, returning branch info embedded as part of the
response.

Build with id 1, references branch_id=2 (which is a duplicate of branch with id
1). We then delete branch with id=2, meaning that the join between
builds/branches will return no data.

The app with either raise an error because of missing records or return empty
data, causing the client to error out.

In order to fix this, we need to ensure that foreign keys are updated to point
to the correct branch.

Our process:
Find duplicate records.
Start a transaction.
Update the foreign keys of the dependent tables to point to the one true record                                                                             finally, delete the duplicates

builds
commits
crons
requests
=end

namespace :moss do
  desc "Remove branch duplicates from several tables"
  task :remove_duplicate_branches do
    require "travis"
    require "travis/api/v3"
    Travis::Database.connect

    # Find all branches wth duplicate name/repository_id combinations, in batches
    # Select the last updated branch record for each of those branch names
    # Query 4 tables to find refrences to any of those branch ids
    # Replace those references with the one-true-branch-id

    # ActiveRecord::Base.connection.execute "SET statement_timeout = 600000"

    # approx length of ids list ~61K
    ids_of_repositories_with_duplicate_branch_records = Travis::API::V3::Models::Branch.select(:repository_id, :name).group(:repository_id, :name).having("count(*) > 1").to_a.map(&:repository_id).uniq

    # ids_of_repositories_with_duplicate_branch_records.each do |repo_id|
    # Shorten script duration during testing by only taking the first three
    # repos
    ids_of_repositories_with_duplicate_branch_records[0..2].each do |repo_id|
      duplicate_repository_branches = Travis::API::V3::Models::Branch.where(repository_id: repo_id).select(:repository_id, :name).group(:repository_id, :name).having("count(*) > 1").to_a
      # We can't filter on branches unless we have the updated_at attr, but
      # don't get the right results if we do. So splitting this into multiple steps.

      # Get branch names. If we just iterate over duplicate branches (and not
      # the duplicates for a given name), we delete the wrong branches, i.e. we
      # take the newest branch of the group and delete references other places.
      branch_names = duplicate_repository_branches.map(&:name)

      branch_names.each do |branch_name|
        branches = Travis::API::V3::Models::Branch.where(repository_id: repo_id, name: branch_name).to_a

        # Assumption: only the last updated branch is ever used
        # We have seen inconsistencies with this in practice
        chosen_branch = branches.max_by { |branch| branch.updated_at }
        other_branches = branches - [chosen_branch]

        # TODO: We also need to ensure that we update the `last_build_id` to
        # reference the highest existing build that reference either the chosen
        # branch or a duplicate.

        ActiveRecord::Base.transaction do
          builds = Travis::API::V3::Models::Build.where(branch_id: other_branches.map(&:id), repository_id: repo_id).to_a
          puts "would update branch id to #{chosen_branch.id} for the following build ids: #{builds.map(&:id)}"
          # .update_all(branch_id: chosen_branch.id)
          commits = Travis::API::V3::Models::Commit.where(branch_id: other_branches.map(&:id), repository_id: repo_id).to_a
          puts "would update branch id to #{chosen_branch.id} for the following commit ids: #{commits.map(&:id)}"
          # .update_all(branch_id: chosen_branch.id)
          crons = Travis::API::V3::Models::Cron.where(branch_id: other_branches).to_a
          puts "would update branch id to #{chosen_branch.id} for the following cron ids: #{crons.map(&:id)}"
          # .update_all(branch_id: chosen_branch.id)
          requests = Travis::API::V3::Models::Request.where(branch_id: other_branches).to_a
          puts "would update branch id to #{chosen_branch.id} for the following request ids: #{requests.map(&:id)}"
          # .update_all(branch_id: chosen_branch.id)

          puts "Would destroy other branches w/ids: #{other_branches.map(&:id)}"
          # Travis::API::V3::Models::Branch.destroy(other_branches)
        end
      end
    end
  end
end

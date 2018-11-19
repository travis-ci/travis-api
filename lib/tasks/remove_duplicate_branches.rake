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
  ids_of_repositories_with_duplicate_branch_records =
    Travis::API::V3::Models::Branch
      .select(:repository_id, :name)
      .group(:repository_id, :name)
      .having("count(*) > 1")
      .to_a.map(&:repository_id).uniq

  ids_of_repositories_with_duplicate_branch_records[0..2].each do |repo_id|
    branches = Travis::API::V3::Models::Branch
      .where(repository_id: repo_id)
      .select(:repository_id, :name)
      .group(:repository_id, :name)
      .having("count(*) > 1")
      .to_a

    # Assumption: only the last updated branch is ever used
    # We have seen inconsistencies with this in practice
    chosen_branch = branches.max_by { |branch| branch.updated_at }
    other_branches = branches - [chosen_branch]

    ActiveRecord::Base.transaction do
      builds = Travis::API::V3::Models::Build
        .where(branch_id: other_branches)
        .to_a
      puts "would update branch id to #{chosen_branch.id} for the following cron ids: #{builds.map(&:id)}"
        # .update_all(branch_id: chosen_branch.id)
      commits = Travis::API::V3::Models::Commit
        .where(branch_id: other_branches)
        .to_a
      puts "would update branch id to #{chosen_branch.id} for the following cron ids: #{commits.map(&:id)}"
        # .update_all(branch_id: chosen_branch.id)
      crons = Travis::API::V3::Models::Cron
        .where(branch_id: other_branches)
        .to_a
      puts "would update branch id to #{chosen_branch.id} for the following cron ids: #{crons.map(&:id)}"
        # .update_all(branch_id: chosen_branch.id)
      requests = Travis::API::V3::Models::Request
        .where(branch_id: other_branches)
        .to_a
      puts "would update branch id to #{chosen_branch.id} for the following request ids: #{requests.map(&:id)}"
        # .update_all(branch_id: chosen_branch.id)

      puts "Would destroy other branches w/ids: #{other_branches.map(&:id)}"
      # Travis::API::V3::Models::Branch.destroy(other_branches)
    end
  end
end

task default: :remove_duplicate_branches

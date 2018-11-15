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

# Find all duplicated branch names, in batches
# Select the last updated branch record for each of those branch names
# Query 4 tables to find refrences to any of those branch ids
# Replace those references with the one-true-branch-id

  Travis::API::V3::Models::Branch.select(:repository_id, :name).group(:repository_id, :name).having("count(*) > 1").limit(50) do |branches|
  # .find_in_batches(batch_size: 50) do |branches|
    puts branches
    # most_recent_branch = branches.max_by { |branch| branch.updated_at }

  end
end

task default: :remove_duplicate_branches

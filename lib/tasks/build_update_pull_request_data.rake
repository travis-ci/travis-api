namespace :build do
  namespace :migrate do
    task :pull_request_data do
      require 'travis'
      Travis::Database.connect

      Build.pull_requests.includes(:request).find_in_batches do |builds|
        Build.transaction do
          builds.each do |build|
            attrs = {
              :pull_request_number => build.request.pull_request_number,
              :pull_request_title  => build.request.pull_request_title
            }

            Build.where(id: build.id).update_all(attrs)
          end
        end
      end
    end
  end
end

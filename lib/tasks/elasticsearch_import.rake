namespace :elasticsearch do
  desc "Import data into Elasticsearch"
  task import: :environment do
    models = [User, Organization, Build, Job, Repository, Request]

    models.each do |model|
      if model.respond_to?(:with_dependencies)
        model.__elasticsearch__.import(scope: :with_dependencies, force: true)
      else
        model.__elasticsearch__.import(force: true)
      end
    end
  end
end

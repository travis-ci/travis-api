if Rails.env.development?
  Elasticsearch::Model.client = Elasticsearch::Client.new log: true
end

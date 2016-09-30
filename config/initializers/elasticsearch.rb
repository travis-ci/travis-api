if Rails.env.development?
  Elasticsearch::Model.client = Elasticsearch::Client.new(log: true)
end

if Rails.env.production?
  Elasticsearch::Model.client = Elasticsearch::Client.new(url: ENV['BONSAI_URL'])
end

module Travis::API::V3
  class Services::Requests::Find < Service
    paginate
    def run!
      $stderr.puts "this is the start of run! in the Service"
      query.find(find(:repository))
    end
  end
end

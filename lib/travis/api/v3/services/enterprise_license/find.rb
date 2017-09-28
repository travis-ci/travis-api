module Travis::API::V3
  class Services::EnterpriseLicense::Find < Service
    def run!
      response = Faraday.get 'http://localhost:8800/license.json'
      replicated_response = JSON.parse(response.body)
      result(replicated_response)
    end
  end
end
describe Travis::API::V3::Services::MigrationRequests::Create, set_app: true do
  before {
    ActiveRecord::Base.connection.execute("truncate migration_requests cascade")
  }

  describe "not authenticated" do
    before  { post("/v3/migration_requests")      }
    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    }}
  end
end

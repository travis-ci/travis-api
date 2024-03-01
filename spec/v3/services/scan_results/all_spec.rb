describe Travis::API::V3::Services::ScanResults::All, set_app: true, scanner_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:scanner_url) { 'http://scanner' }
  let(:scanner_auth_key) { 'secret' }

  before do
    Travis.config.scanner.url = scanner_url
    Travis.config.scanner.token = scanner_auth_key
  end

  let(:authorization) { { 'permissions' => ['repository_scans_view'] } }

  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  context 'unauthenticated' do
    it 'responds 403' do
      get('/v3/scan_results')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:repository) { FactoryBot.create(:repository) }
    let(:job) { FactoryBot.create(:job) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:offset) { '0' }
    let(:limit) { '25' }
    let(:expected_json) do
      {
        "@type"=>"scan_results",
        "@href"=>"/v3/scan_results?repository_id=#{repository.id}&offset=0&limit=25",
        "@representation"=>"standard",
        "@pagination"=>
        {
          "limit"=>25,
          "offset"=>0,
          "count"=>1,
          "is_first"=>true,
          "is_last"=>true,
          "next"=>nil,
          "prev"=>nil,
          "first"=>{
            "@href"=>"/v3/scan_results?repository_id=#{repository.id}&offset=0&limit=25",
            "offset"=>0,
            "limit"=>25
          },
          "last"=>{
            "@href"=>"/v3/scan_results?repository_id=#{repository.id}&offset=0&limit=25",
            "offset"=>0,
            "limit"=>25
          }
        },
        "scan_results"=>[
          {
            "@type"=>"scan_result",
            "@representation"=>"standard",
            "id"=>1,
            "created_at"=>"2022-10-20T08:55:20.522Z",
            "formatted_content"=>
              "travis_fold:start:trivy\r\e[0K\e[33;1mIn line 1 of your build job log trivy found\e[0m\n" +
              "AWS Access Key ID\n" +
              "travis_fold:end:trivy\n" +
              "\n" +
              "\n" +
              "travis_fold:start:detect_secrets\r\e[0K\e[33;1mIn line 1 of your build job log detect_secrets found\e[0m\n" +
              "AWS Access Key\n" +
              "travis_fold:end:detect_secrets\n" +
              "\n" +
              "\n" +
              "\n" +
              "\n" +
              "Our backend build job log monitoring uses:\n" +
              " \u2022 trivy\n" +
              " \u2022 detect_secrets\n" +
              "Called via command line and under respective permissive licenses.",
            "issues_found"=>1,
            "job_id"=>job.id,
            "build_id"=>nil,
            "job_number"=>"1",
            "build_number"=>"1",
            "job_finished_at"=>nil,
            "commit_sha"=>"SHA",
            "commit_compare_url"=>nil,
            "commit_branch"=>nil,
            "build_created_by"=>nil
          }
        ]
      }
    end

    before do
      stub_scanner_request(:get, '/scan_results', query: "repository_id=#{repository.id}&page=#{(offset.to_i / limit.to_i) + 1}&limit=#{limit}", auth_key: scanner_auth_key)
        .to_return(body: JSON.generate(scanner_scan_results_response(job.id)), headers: {'Content-Type' => 'application/json'})
    end

    context 'with push access to repository' do
      before { repository.permissions.create(user: user, push: true) }        

      it 'responds with list of plugins' do
        get('/v3/scan_results', { repository_id: repository.id, offset: offset, limit: limit }, headers)
        expect(last_response.status).to eq(200)
        expect(parsed_body).to eql_json(expected_json)
      end
    end

    context 'without push access to repository' do
      before { repository.permissions.create(user: user, push: false) }        
      let(:authorization) { { 'permissions' => [] } }

      it 'responds with list of plugins' do
        get('/v3/scan_results', { repository_id: repository.id, offset: offset, limit: limit }, headers)
        expect(last_response.status).to eq(403)
        expect(JSON.load(body).to_s).to include(
          "@type",
          "error_type",
          "insufficient_access",
          "error_message",
          "operation requires check_scan_results access to repository",
          "resource_type",
          "repository",
          "permission",
          "check_scan_results")
      end
    end
  end
end

module Support
  module ScannerSpecHelper
    def stub_scanner_request(method, path, query: '', auth_key:)
      url = URI(scanner_url).tap do |url|
        url.path = path
        url.query = query
      end.to_s
      stub_request(method, url).with(headers: { 'Authorization' => "Token token=\"#{auth_key}\"" })
    end

    def scanner_scan_results_response(job_id)
      {
        "scan_results" => [
          {
            "id"=>1,
            "log_id"=>1,
            "job_id"=>job_id,
            "owner_id"=>9830,
            "owner_type"=>"User",
            "created_at"=>"2022-10-20T08:55:20.522Z",
            "content"=>{
              "1"=>[
                {
                  "size"=>20,
                  "column"=>9,
                  "plugin_name"=>"trivy",
                  "finding_name"=>"AWS Access Key ID"
                },
                {
                  "size"=>-1,
                  "column"=>-1,
                  "plugin_name"=>"detect_secrets",
                  "finding_name"=>"AWS Access Key"
                }
              ]
            },
            "issues_found"=>1,
            "archived"=>nil,
            "purged_at"=>nil,
            "job_number"=>"1",
            "build_id"=>nil,
            "build_number"=>"1",
            "job_finished_at"=>nil,
            "commit_sha"=>"SHA",
            "commit_compare_url"=>nil,
            "commit_branch"=>nil,
            "repository_id"=>4,
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
             " • trivy\n" +
             " • detect_secrets\n" +
             "Called via command line and under respective permissive licenses."
          }
        ],
        "total_count"=>1
      }
    end

    def scanner_scan_result_response(job_id, repo_id)
      {
        "scan_result" => {
          "id"=>1,
          "log_id"=>1,
          "job_id"=>job_id,
          "owner_id"=>9830,
          "owner_type"=>"User",
          "created_at"=>"2022-10-20T08:55:20.522Z",
          "content"=>{
            "1"=>[
              {
                "size"=>20,
                "column"=>9,
                "plugin_name"=>"trivy",
                "finding_name"=>"AWS Access Key ID"
              },
              {
                "size"=>-1,
                "column"=>-1,
                "plugin_name"=>"detect_secrets",
                "finding_name"=>"AWS Access Key"
              }
            ]
          },
          "issues_found"=>1,
          "archived"=>nil,
          "purged_at"=>nil,
          "job_number"=>"1",
          "build_id"=>nil,
          "build_number"=>"1",
          "job_finished_at"=>nil,
          "commit_sha"=>"SHA",
          "commit_compare_url"=>nil,
          "commit_branch"=>nil,
          "repository_id"=>repo_id,
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
           " • trivy\n" +
           " • detect_secrets\n" +
           "Called via command line and under respective permissive licenses."
        }
      }
    end
  end
end

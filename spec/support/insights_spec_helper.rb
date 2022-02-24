module Support
  module InsightsSpecHelper
    def stub_insights_request(method, path, query: '', auth_key:, user_id:)
      url = URI(insights_url).tap do |url|
        url.path = path
        url.query = query
      end.to_s
      stub_request(method, url).with(headers: { 'X-Travis-User-Id' => user_id, 'Authorization' => "Token token=\"#{auth_key}\"" })
    end

    def insights_notifications_response
      {
        "data" => [
          {
            "id"=>8,
            "type"=>nil,
            "active"=>true,
            "weight"=>nil,
            "message"=>"This is a test notification",
            "plugin_name"=>"Travis Insights",
            "plugin_type"=>"Travis Insights",
            "plugin_category"=>"Monitoring",
            "probe_severity"=>"high",
            "description"=>"This is a test notification",
            "description_link"=>nil
          },
          {
             "id"=>7,
              "type"=>nil,
              "active"=>true,
              "weight"=>nil,
              "message"=>"This is a test notification",
              "plugin_name"=>"Travis Insights",
              "plugin_type"=>"Travis Insights",
              "plugin_category"=>"Monitoring",
              "probe_severity"=>"high",
              "description"=>"This is a test notification",
              "description_link"=>nil
          },
        ],
        "total_count"=>2
      }
    end

    def insights_probes_response
      {
        "data" => [
          {
            "id"=>312,
            "user_id"=>45,
            "user_plugin_id"=>nil,
            "test_template_id"=>312,
            "uuid"=>"d0286ba6-ee08-4d87-9fb5-e8709fd9d2c3",
            "uuid_group"=>"4bf1205a-e030-4da9-ad16-6d4ac2c654c3",
            "type"=>"native",
            "notification"=>"You need more plugins.",
            "description"=>"Travis Insights description.",
            "description_link"=>"link",
            "test"=>"assert count($.Plugins) > 4",
            "base_object_locator"=>nil,
            "preconditions"=>nil,
            "conditionals"=>nil,
            "object_key_locator"=>nil,
            "active"=>true,
            "editable"=>false,
            "template_type"=>"TestDefinitions::Sre::YouNeedMorePlugins",
            "cruncher_type"=>"sreql",
            "status"=>"Active",
            "labels"=>{},
            "plugin_type"=>"sre",
            "plugin_type_name"=>"Travis Insights",
            "plugin_category"=>"Monitoring",
            "tag_list"=> [
              {
                "id"=>3,
                "name"=>"TI",
                "created_at"=>"2022-01-03T09:21:12.390Z",
                "updated_at"=>"2022-01-03T09:21:12.390Z",
                "taggings_count"=>1
              }
            ],
            "severity"=>"info"
          },
          {
            "id"=>313,
            "user_id"=>45,
            "user_plugin_id"=>nil,
            "test_template_id"=>313,
            "uuid"=>"f3abd5e4-8231-4afa-9b84-56bfa0264f34",
            "uuid_group"=>"d968832e-1b04-4b05-b810-884d0fb5fdee",
            "type"=>"native",
            "notification"=>"You need some deployment pipeline plugins.",
            "description"=>"Description",
            "description_link"=>"",
            "test"=>"assert count($.Plugins[@.plugin_category is \"deployment_pipeline\"]) > 0",
            "base_object_locator"=>nil,
            "preconditions"=>nil,
            "conditionals"=>nil,
            "object_key_locator"=>nil,
            "active"=>true,
            "editable"=>false,
            "template_type"=>"TestDefinitions::Sre::YouNeedSomeDeploymentPipelinePlugins",
            "cruncher_type"=>"sreql",
            "status"=>"Active",
            "labels"=>{},
            "plugin_type"=>"sre",
            "plugin_type_name"=>"Travis Insights",
            "plugin_category"=>"Monitoring",
            "tag_list"=>[],
            "severity"=>"high"
          },
        ],
        "total_count"=>2
      }      
    end

    def insights_create_probe_response(attributes={})
      {
        "id"=>313,
        "user_id"=>45,
        "user_plugin_id"=>nil,
        "test_template_id"=>313,
        "uuid"=>"f3abd5e4-8231-4afa-9b84-56bfa0264f34",
        "uuid_group"=>"d968832e-1b04-4b05-b810-884d0fb5fdee",
        "type"=>"native",
        "notification"=>"You need some deployment pipeline plugins.",
        "description"=>"Description",
        "description_link"=>"",
        "test"=>"assert count($.Plugins[@.plugin_category is \"deployment_pipeline\"]) > 0",
        "base_object_locator"=>nil,
        "preconditions"=>nil,
        "conditionals"=>nil,
        "object_key_locator"=>nil,
        "active"=>true,
        "editable"=>false,
        "template_type"=>"TestDefinitions::Sre::YouNeedSomeDeploymentPipelinePlugins",
        "cruncher_type"=>"sreql",
        "status"=>"Active",
        "labels"=>{},
        "plugin_type"=>"sre",
        "plugin_type_name"=>"Travis Insights",
        "plugin_category"=>"Monitoring",
        "tag_list"=>[],
        "severity"=>"high"
      }.deep_merge(attributes)
    end

    def insights_plugins_response
      {
        "data"=> [
          {
            "id"=>5,
            "name"=>"KubePlugin",
            "public_id"=>"TID6CD47CD6E26",
            "plugin_type"=>"Kubernetes Cluster",
            "plugin_category"=>"Monitoring",
            "last_scan_end"=>nil,
            "scan_status"=>"In Progress",
            "plugin_status"=>"Active",
            "active"=>true
          },
          {
            "id"=>3,
            "name"=>"KubePlugin2",
            "public_id"=>"TI74D0AACAC0BD",
            "plugin_type"=>"Kubernetes Cluster",
            "plugin_category"=>"Monitoring",
            "last_scan_end"=>"2021-12-01 10:44:32",
            "scan_status"=>"Success",
            "plugin_status"=>"Active",
            "active"=>true
          }
        ],
        "total_count"=>2
      }
    end

    def insights_create_plugin_response(attributes={})
      {
        "plugin" => {
          "id"=>3,
          "name"=>"KubePlugin2",
          "public_id"=>"TI74D0AACAC0BD",
          "plugin_type"=>"Kubernetes Cluster",
          "plugin_category"=>"Monitoring",
          "last_scan_end"=>"2021-12-01 10:44:32",
          "scan_status"=>"Success",
          "plugin_status"=>"Active",
          "active"=>true
        }.deep_merge(attributes)
      }
    end

    def insights_public_key_response
      {
        "key_hash"=>"KEY_HASH",
        "key_body"=>"PUBLIC_KEY",
        "ordinal_value"=>1
      }
    end

    def insights_authenticate_key_response
      {
        "success"=>true,
        "error_msg"=>""
      }
    end

    def insights_scan_log_response
      {
        "scan_logs"=>[
          {
            "id"=>97396,
            "user_plugin_id"=>255,
            "test_template_id"=>nil,
            "log_type"=>"notifications",
            "text"=>"Scheduling scan",
            "additional_text_type"=>nil,
            "additional_text"=>nil,
            "created_at"=>"2021-11-18 04:00:05"
          },
          {
            "id"=>97432,
            "user_plugin_id"=>255,
            "test_template_id"=>nil,
            "log_type"=>"plugin",
            "text"=>"Scan started at",
            "additional_text_type"=>nil,
            "additional_text"=>nil,
            "created_at"=>"2021-11-18 04:00:07"
          }
        ],
        "meta"=>{
          "scan_status_in_progress"=>true
        }
      }
    end

    def insights_template_plugin_tests_response
      {
        "template_tests"=>[
          {
            "id"=>3232,
            "name"=>"This is a test probe"
          },
          {
            "id"=>3234,
            "name"=>"This is a test probe 2"
          }
        ],
        "plugin_category"=>"Monitoring"
      }
    end

    def insights_sandbox_plugins_response
      {
        "plugins"=>[
          {
            "id"=>4,
            "name"=>"Travis Insights",
            "data"=>"{\n  \"Plugins\": [\n    {\n      \"id\": 255,\n      \"plugin_category\": \"monitoring\",\n      \"plugin_type\": \"sre\",\n      \"scan_logs\": [\n        {\n          \"additional_text\": null,\n          \"additional_text_type\": null,\n          \"created_at\": \"2021-11-18T04:00:05.072Z\",\n          \"id\": 97396,\n          \"log_type\": \"notifications\",\n          \"tenant_id\": 39,\n          \"test_template_id\": null,\n          \"text\": \"Scheduling scan\",\n          \"updated_at\": \"2021-11-18T04:00:05.072Z\",\n          \"user_plugin_id\": 255\n        },\n        {\n          \"additional_text\": null,\n          \"additional_text_type\": null,\n          \"created_at\": \"2021-11-18T04:00:07.010Z\",\n          \"id\": 97432,\n          \"log_type\": \"plugin\",\n          \"tenant_id\": 39,\n          \"test_template_id\": null,\n          \"text\": \"Scan started at\",\n          \"updated_at\": \"2021-11-18T04:00:07.010Z\",\n          \"user_plugin_id\": 255\n        },\n        {\n          \"additional_text\": \"\",\n          \"additional_text_type\": \"\",\n          \"created_at\": \"2021-11-18T04:00:07.068Z\",\n          \"id\": 97435,\n          \"log_type\": \"plugin\",\n          \"tenant_id\": 39,\n          \"test_template_id\": null,\n          \"text\": \"Accessing APIs:\",\n          \"updated_at\": \"2021-11-18T04:00:07.068Z\",\n          \"user_plugin_id\": 255\n        },\n        {\n          \"additional_text\": \"- User Plugins\",\n          \"additional_text_type\": \"info\",\n          \"created_at\": \"2021-11-18T04:00:07.148Z\",\n          \"id\": 97438,\n          \"log_type\": \"plugin\",\n          \"tenant_id\": 39,\n          \"test_template_id\": null,\n          \"text\": \"\",\n          \"updated_at\": \"2021-11-18T04:00:07.148Z\",\n          \"user_plugin_id\": 255\n        }\n      ],\n      \"user_id\": 28\n    }\n  ]\n}",
            "ready"=>true
          }
        ]
      }
    end

    def insights_sandbox_plugin_data_response
      "{\n  \"Plugins\": [\n    {\n      \"id\": 255,\n      \"plugin_category\": \"monitoring\",\n      \"plugin_type\": \"sre\",\n      \"scan_logs\": [\n        {\n          \"additional_text\": null,\n          \"additional_text_type\": null,\n          \"created_at\": \"2021-11-18T04:00:05.072Z\",\n          \"id\": 97396,\n          \"log_type\": \"notifications\",\n          \"tenant_id\": 39,\n          \"test_template_id\": null,\n          \"text\": \"Scheduling scan\",\n          \"updated_at\": \"2021-11-18T04:00:05.072Z\",\n          \"user_plugin_id\": 255\n        },\n        {\n          \"additional_text\": null,\n          \"additional_text_type\": null,\n          \"created_at\": \"2021-11-18T04:00:07.010Z\",\n          \"id\": 97432,\n          \"log_type\": \"plugin\",\n          \"tenant_id\": 39,\n          \"test_template_id\": null,\n          \"text\": \"Scan started at\",\n          \"updated_at\": \"2021-11-18T04:00:07.010Z\",\n          \"user_plugin_id\": 255\n        },\n        {\n          \"additional_text\": \"\",\n          \"additional_text_type\": \"\",\n          \"created_at\": \"2021-11-18T04:00:07.068Z\",\n          \"id\": 97435,\n          \"log_type\": \"plugin\",\n          \"tenant_id\": 39,\n          \"test_template_id\": null,\n          \"text\": \"Accessing APIs:\",\n          \"updated_at\": \"2021-11-18T04:00:07.068Z\",\n          \"user_plugin_id\": 255\n        },\n        {\n          \"additional_text\": \"- User Plugins\",\n          \"additional_text_type\": \"info\",\n          \"created_at\": \"2021-11-18T04:00:07.148Z\",\n          \"id\": 97438,\n          \"log_type\": \"plugin\",\n          \"tenant_id\": 39,\n          \"test_template_id\": null,\n          \"text\": \"\",\n          \"updated_at\": \"2021-11-18T04:00:07.148Z\",\n          \"user_plugin_id\": 255\n        }\n      ],\n      \"user_id\": 28\n    }\n  ]\n}"
    end

    def insights_sandbox_query_response
      {
        "negative_results"=>[
          false
        ],
        "positive_results"=>nil,
        "success"=>true
      }
    end

    def insights_tags_response
      [
        { 'name'=>'Tag1' },
        { 'name'=>'Tag2' },
        { 'name'=>'Tag3' }
      ]
    end

    def insights_generate_key_response
      {
        "keys" => [
          "TIDE0C7A9C1D5E",
          "a8f702e9363e8573dd476c116e62cf6e04e44c8610dc939c67e45777f2b6cbdb"
        ]
      }
    end

    def spotlight_summaries_response
      {
        "@type": "spotlight_summary",
        "data": [
            {
                "id": 1,
                "user_id": 123,
                "repo_id": "1223",
                "build_status": "complete",
                "repo_name": "myrepo",
                "builds": 4,
                "duration": 47,
                "credits": 23,
                "user_license_credits_consumed": 20,
                "time": "2021-11-08T12:13:14.000Z"
            }
        ]
      }
    end
  end
end

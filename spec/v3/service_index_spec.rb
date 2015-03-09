require 'spec_helper'

describe Travis::API::V3::ServiceIndex do
  let(:headers)  {{                        }}
  let(:path)     { '/'                      }
  let(:json)     { JSON.load(response.body) }
  let(:response) { get(path, {}, headers)   }

  describe "custom json entry point" do
    let(:expected_resources) {
      {"requests"=>
        {"@type"=>"resource",
         "actions"=>
          {"find"=>
            [{"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}repo/{repository.id}/requests"}],
           "create"=>
            [{"@type"=>"template",
              "request_method"=>"POST",
              "uri_template"=>"#{path}repo/{repository.id}/requests"}]}},
       "branch"=>
        {"@type"=>"resource",
         "actions"=>
          {"find"=>
            [{"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}repo/{repository.id}/branch/{branch.name}"}]},
         "attributes"=>["name", "last_build", "repository"]},
       "repository"=>
        {"@type"=>"resource",
         "actions"=>
          {"find"=>
            [{"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}repo/{repository.id}"}],
           "enable"=>
            [{"@type"=>"template",
              "request_method"=>"POST",
              "uri_template"=>"#{path}repo/{repository.id}/enable"}],
           "disable"=>
            [{"@type"=>"template",
              "request_method"=>"POST",
              "uri_template"=>"#{path}repo/{repository.id}/disable"}]},
         "attributes"=>
          ["id",
           "slug",
           "name",
           "description",
           "github_language",
           "active",
           "private",
           "owner",
           "last_build",
           "default_branch"]},
       "repositories"=>
        {"@type"=>"resource",
         "actions"=>
          {"for_current_user"=>
            [{"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}repos"}]}},
       "build"=>
        {"@type"=>"resource",
         "actions"=>
          {"find"=>
            [{"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}build/{build.id}"}]},
         "attributes"=>
          ["id",
           "number",
           "state",
           "duration",
           "started_at",
           "finished_at",
           "repository",
           "branch"]},
       "organization"=>
        {"@type"=>"resource",
         "actions"=>
          {"find"=>
            [{"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}org/{organization.id}"}]},
         "attributes"=>["id", "login", "name", "github_id"]},
       "organizations"=>
        {"@type"=>"resource",
         "actions"=>
          {"for_current_user"=>
            [{"@type"=>"template",
              "request_method"=>"GET",
              "uri_template"=>"#{path}orgs"}]}}}
    }

    describe 'with /v3 prefix' do
      let(:path) { '/v3/' }
      specify(:resources) { expect(json['resources']).to be == expected_resources }
    end

    describe 'with Accept header' do
      let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.3+json' } }
      specify(:resources) { expect(json['resources']).to be == expected_resources }
    end

    describe 'with Travis-API-Version header' do
      let(:headers) { { 'HTTP_TRAVIS_API_VERSION' => '3' } }
      specify(:resources) { expect(json['resources']).to be == expected_resources }
    end
  end

  describe "json-home document" do
    describe 'with /v3 prefix' do
      let(:headers) { { 'HTTP_ACCEPT' => 'application/json-home' } }
      let(:path) { '/v3/' }
      specify(:resources) { expect(json['resources']).to include("http://schema.travis-ci.com/rel/repository/find") }
    end

    describe 'with Travis-API-Version header' do
      let(:headers) { { 'HTTP_ACCEPT' => 'application/json-home', 'HTTP_TRAVIS_API_VERSION' => '3' } }
      specify(:resources) { expect(json['resources']).to include("http://schema.travis-ci.com/rel/repository/find") }
    end
  end
end

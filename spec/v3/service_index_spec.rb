require 'spec_helper'

describe Travis::API::V3::ServiceIndex do
  let(:headers)  {{                        }}
  let(:path)     { '/'                      }
  let(:json)     { JSON.load(response.body) }
  let(:response) { get(path, {}, headers)   }

  describe "custom json entry point" do
    let(:expected_resources) {{
      "repository"          =>  {
        "find"              => [{"request-method"=>"GET",  "uri-template"=>"#{path}repo/{repository.id}"}] },
      "repositories"        =>  {
        "for_current_user"  => [{"request-method"=>"GET",  "uri-template"=>"#{path}repos"}] },
      "branch"              =>  {
        "find"              => [{"request-method"=>"GET",  "uri-template"=>"#{path}repo/{repository.id}/branch/{branch.name}"}]},
      "build"               =>  {
        "find"              => [{"request-method"=>"GET",  "uri-template"=>"#{path}build/{build.id}"}] },
      "organizations"       =>  {
        "for_current_user"  => [{"request-method"=>"GET",  "uri-template"=>"#{path}orgs"}] },
      "organization"        =>  {
        "find"              => [{"request-method"=>"GET",  "uri-template"=>"#{path}org/{organization.id}"}] },
      "requests"            =>  {
        "find"              => [{"request-method"=>"GET",  "uri-template"=>"#{path}repo/{repository.id}/requests"}],
        "create"            => [{"request-method"=>"POST", "uri-template"=>"#{path}repo/{repository.id}/requests"}]}
    }}

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

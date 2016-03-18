require 'spec_helper'

describe Travis::API::V3::Services::Lint::Lint do
    let(:content) { "foo: bar" }
    let(:parsed_body) { JSON.load(last_response.body) }

  describe "accepts content in parameter" do
    before        { post("v3/lint", content: content )  }
    example       { expect(last_response).to be_ok }
    example       { expect(parsed_body).to be == {
                    "@warnings"         => [{
                      "@type"           => "warning",
                      "message"         => "query parameter foo: bar not whitelisted, ignored",
                      "warning_type"    => "ignored_parameter", "parameter"=>"foo: bar"}],
                    "@type"             =>  "lint",
                    "warnings"          => [{
                      "key"             => [],
                      "message"         => "unexpected key \"foo\", dropping"}, {
                      "key"             => [],
                      "message"         => "missing key \"language\", defaulting to \"ruby\""}]}
                  }
  end

  describe "accepts content as body" do
    before        { post("/v3/lint", content)  }
    example       { expect(last_response).to be_ok }
    example       { expect(parsed_body).to be == {
                    "@warnings"         => [{
                      "@type"           => "warning",
                      "message"         => "query parameter foo: bar not whitelisted, ignored",
                      "warning_type"    => "ignored_parameter", "parameter"=>"foo: bar"}],
                    "@type"             =>  "lint",
                    "warnings"          => [{
                      "key"             => [],
                      "message"         => "unexpected key \"foo\", dropping"}, {
                      "key"             => [],
                      "message"         => "missing key \"language\", defaulting to \"ruby\""}]}
                  }
  end
end

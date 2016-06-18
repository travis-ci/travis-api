describe Travis::API::V3::Services::Lint::Lint, set_app: true do
    let(:content) { "foo: bar" }
    let(:parsed_body) { JSON.load(last_response.body) }
    let(:headers) {{ 'CONTENT_TYPE' => 'text/yaml'}}


  describe "accepts content in parameter" do
    before        { post("v3/lint", content: content )  }
    example       { expect(last_response).to be_ok }
    example       { expect(parsed_body).to be == {
                    "@type"             =>  "lint",
                    "warnings"          => [{
                      "key"             => [],
                      "message"         => "unexpected key \"foo\", dropping"}, {
                      "key"             => [],
                      "message"         => "missing key \"language\", defaulting to \"ruby\""}]}
                  }
  end

  describe "accepts content as body" do
    before        { post("/v3/lint", content, headers)  }
    example       { expect(last_response).to be_ok }
    example       { expect(parsed_body).to be == {
                    "@type"             =>  "lint",
                    "warnings"          => [{
                      "key"             => [],
                      "message"         => "unexpected key \"foo\", dropping"}, {
                      "key"             => [],
                      "message"         => "missing key \"language\", defaulting to \"ruby\""}]}
                  }
  end
end

require 'spec_helper'

describe Travis::Api::App::Endpoint::Lint do
  let(:content) { "foo: bar" }
  let(:body) { "{\"lint\":{\"warnings\":[{\"key\":[],\"message\":\"unexpected key \\\"foo\\\", dropping\"},{\"key\":[],\"message\":\"missing key \\\"language\\\", defaulting to \\\"ruby\\\"\"}]}}" }

  it "accepts content in parameter" do
    response = post('/lint', content: content)
    response.should be_ok
    response.body.should be == body
  end

  it "accepts content as body" do
    response = put('/lint', content)
    response.should be_ok
    response.body.should be == body
  end
end

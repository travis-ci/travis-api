require 'spec_helper'

describe Travis::Api::V2::Http::Annotations do
  include Travis::Testing::Stubs, Support::Formats

  let(:data) { described_class.new([annotation]).data }

  it "annotations" do
    data["annotations"].should eq([{
      'id' => annotation.id,
      'job_id' => test.id,
      'description' => annotation.description,
      'url' => annotation.url,
      'provider_name' => 'Travis CI',
      'status' => '',
    }])
  end
end

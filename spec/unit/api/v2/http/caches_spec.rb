require 'spec_helper'

describe Travis::Api::V2::Http::Branch do
  include Travis::Testing::Stubs, Support::Formats
  let(:data) { Travis::Api::V2::Http::Caches.new([cache]).data }

  specify 'caches' do
    data['caches'].should be == [{
      "repository_id" => 1,
      "size"          => 1000,
      "slug"          => "cache",
      "branch"        => "master",
      "last_modified" => "1970-01-01T00:00:00Z"
    }]
  end
end
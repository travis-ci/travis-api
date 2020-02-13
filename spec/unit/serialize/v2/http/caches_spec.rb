describe Travis::Api::Serialize::V2::Http::Caches do
  include Travis::Testing::Stubs, Support::Formats
  let(:data) { described_class.new([cache]).data }

  specify 'caches' do
    expect(data['caches']).to eq([{
      "repository_id" => 1,
      "size"          => 1000,
      "slug"          => "cache",
      "branch"        => "master",
      "last_modified" => "1970-01-01T00:00:00Z"
    }])
  end
end

describe Travis::Api::Serialize::V2::Http::Broadcasts do
  include Support::Formats

  let(:broadcast) { double(:id => 1, :message => 'yo hey!') }
  let(:data)      { described_class.new([broadcast]).data }

  it 'broadcasts' do
    expect(data['broadcasts'].first).to eq({
      'id' => 1,
      'message' => 'yo hey!'
    })
  end
end

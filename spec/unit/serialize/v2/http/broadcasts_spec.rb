describe Travis::Api::Serialize::V2::Http::Broadcasts do
  include Support::Formats

  let(:broadcast) { stub(:id => 1, :message => 'yo hey!') }
  let(:data)      { described_class.new([broadcast]).data }

  it 'broadcasts' do
    data['broadcasts'].first.should == {
      'id' => 1,
      'message' => 'yo hey!'
    }
  end
end

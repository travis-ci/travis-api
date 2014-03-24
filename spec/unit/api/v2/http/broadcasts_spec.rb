require 'spec_helper'

describe Travis::Api::V2::Http::Broadcasts do
  include Support::Formats

  let(:broadcast) { stub(:id => 1, :message => 'yo hey!') }
  let(:data)      { Travis::Api::V2::Http::Broadcasts.new([broadcast]).data }

  it 'broadcasts' do
    data['broadcasts'].first.should == {
      'id' => 1,
      'message' => 'yo hey!'
    }
  end
end

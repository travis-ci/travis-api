require 'rails_helper'

RSpec.describe PreferencesHelper, type: :helper do
  before {
    class PreferencesTester
      include PreferencesHelper
      attr_writer :preferences

      def preferences
        @preferences ||= {'keep_netrc' => false}
      end

      def save!; end
    end
    @testable = PreferencesTester.new
  }

  describe '#keep_netrc' do
    it 'returns keep_netrc value from preferences' do
      expect(@testable.keep_netrc).to eql(false)
    end

    it 'returns true keep_netrc value for empty preferences' do
      @testable.preferences = {}
      expect(@testable.keep_netrc).to eql(true)
    end
  end
  
  describe '#set_keep_netrc' do
    it 'sets keep_netrc in preferences to true and false' do
      @testable.set_keep_netrc(true)
      expect(@testable.keep_netrc).to eql(true)
      @testable.set_keep_netrc(false)
      expect(@testable.keep_netrc).to eql(false)
    end
  end
end

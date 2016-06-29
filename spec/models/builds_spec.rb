require 'rails_helper'

RSpec.describe Build, type: :model do
  describe '.time' do
    let(:passed_build) { create(:build, state: 'passed', finished_at: '2016-06-29 11:06:01') }

    it 'gets time finished_at for a build with state passed' do
      expect(passed_build.time.to_s).to eql '2016-06-29 11:06:01 UTC'
    end
  end
end

require 'rails_helper'

RSpec.describe Services::Abuse::Update do
  describe '#call' do
    context 'when trusted' do
      let!(:user) { create(:user) }
      context 'when marked as offender' do
        it 'create abuse object for user' do

        end
      end
    end
  end
end
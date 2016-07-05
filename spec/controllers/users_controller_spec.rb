require 'rails_helper'
require 'support/auth_helper'

RSpec.describe UsersController, type: :controller do
  include AuthHelper

  describe 'GET #show' do
    context 'as an admin user' do
      let!(:user) { create(:user) }
      before(:each) { admin_login }
      before(:each) { get :show, id: user.id }

      it 'is successful' do
        expect(response).to be_success
      end

      it 'renders the show template with valid user' do
        expect(response).to render_template("show")
      end
    end
  end
end

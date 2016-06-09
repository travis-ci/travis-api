require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  describe 'GET #show' do

    # We need to setup FactoryGirl in this too. Not sure if it's just

    # Not sure how to setup for an authorized user and unauthorized user yet, either.
    # I know there is an admin status flag of some sort (which is an authorized user).

    context 'as an admin user' do
      let!(:user) { FactoryGirl.create(:user) }
      before(:each) { get :show, id: 125283 }

      it 'assigns valid user to @user' do
        expect(assigns(:user)).to eq user
      end

      it 'is successful' do
        expect(response).to be_success
      end

      it 'renders the show template with valid user' do
        expect(response).to render_template("show")
      end

      it 'does something when a user doesn\'t exist' do
        # TODO: are we redirecting to a not found page or throwing an exception?
      end

      it 'doesn\'t assign invalid user to @user' do
        # TODO: do we need this? If it redirects or throws an error first anyway, does it matter if @user is misassigned?
      end
    end

    context 'as an unauthorized user' do
      it 'fails' do
        # expect(response).not_to be_success
      end

      it 'requests authorization' do
        # TODO: Or we could also just say forbidden.
      end
    end
  end
end

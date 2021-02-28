# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:unauthorized_user) { FactoryBot.create(:user) }

  let(:valid_attributes) do
    {
      uid: 'fg1248',
      email: 'fg1248@example.com',
      first_name: 'fitzgerald',
      last_name: 'grant',
      deactivated: false
    }
  end

  let(:invalid_attributes) do
    {
      email: ''
    }
  end

  describe 'with sysadmin user' do
    before do
      user.add_role :sysadmin
      login_as user
    end

    describe "GET /index" do
      it "returns http success" do
        get users_path
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET /show" do
      it "renders a successful response" do
        user = User.create! valid_attributes
        get user_url(user)
        expect(response).to be_successful
      end
    end

    describe "GET /edit" do
      it "render a successful response" do
        user = User.create! valid_attributes
        get edit_user_url(user)
        expect(response).to be_successful
      end
    end

    describe "PATCH /update" do
      context "with valid parameters" do
        let(:new_attributes) do
          {
            email: 'br1589@example.com'
          }
        end

        it "updates the requested user" do
          user = User.create! valid_attributes
          patch user_url(user), params: { user: new_attributes }
          user.reload
          expect(user.email).to eq('br1589@example.com')
        end

        it "redirects to the user" do
          user = User.create! valid_attributes
          patch user_url(user), params: { user: new_attributes }
          user.reload
          expect(response).to redirect_to(user_url(user))
        end
      end

      context "with invalid parameters" do
        it "renders a successful response (i.e. to display the 'edit' template)" do
          user = User.create! valid_attributes
          patch user_url(user), params: { user: invalid_attributes }
          expect(response).to be_successful
        end
      end
    end

    describe "POST /create" do
      it "correctly responds with invalid attributes" do
        post users_url, params: { user: invalid_attributes }
        expect(response).to be_successful
        expect(response.body).to include('<h1>Create User</h1>')
      end
    end
  end

  describe 'with anauthorized user' do
    before do
      login_as unauthorized_user
    end

    it "does not render the index" do
      get users_path
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

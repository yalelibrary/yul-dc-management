# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Roles', type: :request do
  let(:authorized_user) { FactoryBot.create(:sysadmin_user) }
  let(:user) { FactoryBot.create(:user) }
  let(:role) { FactoryBot.create(:role) }
  let(:admin_set) { FactoryBot.create(:admin_set) }

  let(:valid_parameters) do
    {
      uid: user.uid,
      role: role,
      item_class: 'AdminSet',
      item_id: admin_set.id
    }
  end

  let(:invalid_parameters) do
    {
      uid: 10,
      role: nil,
      item_class: 'AdminSet',
      item_id: nil
    }
  end

  describe 'with authorized user' do
    before do
      login_as authorized_user
    end

    describe 'POST /create' do
      context 'with valid parameters' do
        it 'adds a role to a user' do
          expect do
            post roles_url, params: valid_parameters
          end.to change(user.roles, :count).by(1)
        end

        it 'does not add duplicate role' do
          expect do
            post roles_url, params: valid_parameters
          end.to change(user.roles, :count).by(1)
          expect do
            post roles_url, params: valid_parameters
          end.not_to change(user.roles, :count)
          expect(response).to have_http_status(302)
        end
      end

      context 'with invalid parameters' do
        it 'does not add a role to a user' do
          expect do
            post roles_url, params: invalid_parameters
          end.to change(user.roles, :count).by(0)
        end
      end
    end

    describe 'DELETE /remove' do
      context 'with valid parameters' do
        it 'removes a role from a user' do
          post roles_url, params: valid_parameters
          expect do
            delete remove_roles_path, params: valid_parameters
          end.to change(user.roles, :count).by(-1)
        end
      end
    end
  end

  describe 'with unauthorized user' do
    before do
      login_as user
    end

    it 'is denied permission to add a role to a user' do
      post roles_url, params: valid_parameters
      expect(response).to have_http_status(401)
    end

    it 'is denied permission to delete a role from a user' do
      delete remove_roles_path, params: valid_parameters
      expect(response).to have_http_status(401)
    end
  end
end

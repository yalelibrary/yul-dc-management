# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Roles', type: :request do
  let(:user) { FactoryBot.create(:sysadmin_user) }
  let(:role) { FactoryBot.create(:role) }
  let(:admin_set) { FactoryBot.create(:admin_set) }

  before do
    login_as user
  end

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

  describe 'POST /create' do
    context 'with valid parameters' do
      it 'adds a role to a user' do
        expect do
          post roles_url, params: valid_parameters
        end.to change(user.roles, :count).by(1)
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

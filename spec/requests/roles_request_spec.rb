# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Roles', type: :request do
  let(:user) { FactoryBot.create(:user) }
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

  let(:valid_attributes) do
    {
      id: 1,
      name: 'viewer',
      resource_type: 'AdminSet',
      resource_id: '1'
    }
  end

  # name { 'editor' }
  # users { [association(:user)] }
  # resource { association :admin_set }

  # let(:invalid_attributes) do
  #   {
  #     name: 'viewer',
  #     resource_type: nil,
  #     resource_id: '2'
  #   }
  # end

  describe 'POST /create' do
    context 'with valid parameters' do
      it 'adds a role to a user' do
        expect do
          post roles_url, params: valid_parameters
        end.to change(user.roles, :count).by(1)
      end
    end

    # context 'with invalid parameters' do
    #   it 'does not create a new Role' do
    #   end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Roles', type: :request do
  let(:user) { FactoryBot.create(:user) }

  before do
    login_as user
  end

  let(:valid_parameters) do
    {
      uid: 'fcr7',
      role: 'viewer',
      item_class: 'AdminSet',
      item_id: '2'
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

  # let(:invalid_attributes) do
  #   {
  #     name: 'viewer',
  #     resource_type: nil,
  #     resource_id: '2'
  #   }
  # end

  describe 'POST /create' do
    context 'with valid parameters' do
      it 'creates a new role' do
        post roles_path, params: { role: valid_parameters }
        byebug
        # expect do
        #   # post roles_path, params: valid_parameters
        #   post roles_path, params: { role: valid_attributes }
        # end.to change(Role, :count).by(1)
      end
    end

    # context 'with invalid parameters' do
    #   it 'does not create a new Role' do
    #   end
    # end
end

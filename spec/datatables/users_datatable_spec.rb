# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserDatatable, type: :datatable do
  let(:user) { FactoryBot.create(:user, uid: 'js2530', email: 'juliasmith@email.com') }
  columns = ['netid', 'email', 'deactivated']

  describe 'user data tables' do
    it 'can handle an empty model set' do
      output = UserDatatable.new(datatable_sample_params(columns)).data

      expect(output).to eq([])
    end

    it 'renders a complete data table' do
      login_as user
      output = UserDatatable.new(datatable_sample_params(columns)).data
      expect(output.size).to eq(1)
      expect(output).to include(
        netid: 'js2530',
        email: 'juliasmith@email.com',
        deactivated: false
      )
    end
  end
end

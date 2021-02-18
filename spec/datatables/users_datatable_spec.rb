# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserDatatable, type: :datatable do
  let(:user) { FactoryBot.create(:user, uid: 'js2530', email: 'juliasmith@email.com') }
  let(:user2) { FactoryBot.create(:user, uid: 'pt4645', email: 'pamthomas@email.com') }
  columns = ['netid', 'email', 'deactivated']

  describe 'user data tables' do
    it 'can handle an empty model set' do
      output = UserDatatable.new(datatable_sample_params(columns)).data

      expect(output).to eq([])
    end

    it 'renders a complete data table' do
      login_as user
      user2.reload
      output = UserDatatable.new(datatable_sample_params(columns)).data
      expect(output.size).to eq(2)
      expect(output[0]).to include(
        netid: 'js2530',
        email: 'juliasmith@email.com',
        deactivated: "Active"
      )
      expect(output[1]).to include(
        netid: 'pt4645',
        email: 'pamthomas@email.com',
        deactivated: "Active"
      )
    end
  end
end

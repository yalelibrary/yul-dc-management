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
      output = UserDatatable.new(datatable_sample_params(columns), view_context: user_datatable_view_mock(user.id, user.uid)).data
      expect(output.size).to eq(1)
      expect(output[0]).to include(
        netid: "<a href='/management/users/#{user.id}'>#{user.uid}</a>",
        email: 'juliasmith@email.com',
        deactivated: "Active",
        actions: "<a href='/management/users/#{user.id}/edit'>Edit</a>"
      )
    end

    it "shows both active and deactivated users" do
      login_as user
      user2.deactivated = true
      user2.save
      output = UserDatatable.new(datatable_sample_params(columns), view_context: user_datatable_view_mock(user.id, user.uid)).data
      expect(output.size).to eq(2)
    end
  end
end

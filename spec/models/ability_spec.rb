# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ability, type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:sysadmin_user) { FactoryBot.create(:user) }

  describe 'for a sysadmin' do
    it 'grants manage role to User' do
      sysadmin_user.add_role :sysadmin
      expect(Ability.new(sysadmin_user).can?(:manage, User)).to be(true)
    end
  end

  describe 'for a non-sysadmin' do
    it 'does not all management of Users' do
      expect(Ability.new(user).can?(:manage, User)).to be(false)
    end
  end
end

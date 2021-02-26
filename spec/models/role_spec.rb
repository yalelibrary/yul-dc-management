# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Role, type: :model do
  let(:user) { FactoryBot.create(:user) }
  let(:set) { FactoryBot.create(:admin_set) }
  let(:role) { FactoryBot.create(:role, users: [user], resource: set) }

  it 'has the expected fields' do
    expect(role.name).to eq('editor')
    expect(role.users).to include(user)
    expect(role.resource).to eq(set)
  end

  it 'allows association of a Role with an Admin Set via Rolify' do
    user.add_role :viewer, set
    expect(User.with_role(:viewer, set)).to include(user)
  end

end

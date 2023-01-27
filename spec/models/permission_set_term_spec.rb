# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PermissionSetTerm, type: :model do
  let(:user) { FactoryBot.create(:user, id: 33) }
  let(:permission_set) { FactoryBot.create(:permission_set) }
  let(:permission_set_terms) { FactoryBot.create(:permission_set_term, permission_set: permission_set) }
  let(:permission_set_terms2) { FactoryBot.create(:permission_set_term, permission_set: permission_set) }

  it "exists" do
    expect(described_class).to be_a(Class)
  end

  it "sets the activate date when activated" do
    expect(permission_set_terms.activated_at).to be nil
    permission_set_terms.activate_by!(user)
    expect(permission_set_terms.activated_at).not_to be nil
  end

  it "sets the inactivate date when inactivated" do
    expect(permission_set_terms.inactivated_at).to be nil
    permission_set_terms.activate_by!(user)
    permission_set_terms.inactivate_by!(user)
    expect(permission_set_terms.inactivated_at).not_to be nil
  end

  it "deactivates prior terms when a new terms is activated" do
    permission_set_terms.activate_by!(user)
    expect(permission_set_terms.inactivated_at).to be nil
    expect(permission_set_terms.activated_at).not_to be nil
    expect(permission_set_terms2.activated_at).to be nil
    permission_set_terms2.activate_by!(user)
    permission_set_terms.reload
    expect(permission_set_terms.inactivated_at).not_to be nil
    expect(permission_set_terms2.activated_at).not_to be nil
  end

  it "has readonly body" do
    permission_set_terms
    old_body = permission_set_terms.body
    permission_set_terms.body = "Test2"
    permission_set_terms.save!
    permission_set_terms.reload
    expect(permission_set_terms.body).to eq old_body
  end

  it "has readonly title" do
    permission_set_terms
    old_title = permission_set_terms.title
    permission_set_terms.title = "Test2 Title"
    permission_set_terms.save!
    permission_set_terms.reload
    expect(permission_set_terms.title).to eq old_title
  end

  it "raises an error when activating an already activated permission_set_terms" do
    permission_set_terms.activate_by!(user)
    expect do
      permission_set_terms.activate_by!(user)
    end.to raise_error("Unable to activate previously activated permission set")
  end

  it "raises an error when inactivating an already inactivated permission_set_terms" do
    permission_set_terms.activate_by!(user)
    permission_set_terms.inactivate_by!(user)
    expect do
      permission_set_terms.inactivate_by!(user)
    end.to raise_error("Unable to inactivate previously inactivated permission set")
  end

  it "raises an error when inactivating a permission_set_terms that was never activated" do
    expect do
      permission_set_terms.inactivate_by!(user)
    end.to raise_error("Unable to inactivate inactivated permission set")
  end
end

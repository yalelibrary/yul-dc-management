# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TermsAgreement, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  let(:request_user) { FactoryBot.create(:permission_request_user) }
  let(:terms) { FactoryBot.create(:permission_set_term, activated_at: Time.zone.now, permission_set_id: permission_set.id) }
  let(:permission_set) { FactoryBot.create(:permission_set, label: 'set 1') }

  before do
    request_user
    terms
    permission_set
  end

  describe 'with valid attributes' do
    it 'is valid' do
      expect(TermsAgreement.new(permission_request_user: request_user, permission_set_term: terms, agreement_ts: Time.zone.now)).to be_valid
    end

    it 'has the expected fields' do
      u = described_class.new
      time = Time.zone.now
      u.permission_request_user = request_user
      u.permission_set_term = terms
      u.agreement_ts = time
      u.save!

      expect(u.errors).to be_empty
      expect(u.permission_request_user).to eq request_user
      expect(u.permission_set_term).to eq terms
      expect(u.agreement_ts).to eq time
    end
  end


end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccessChangeRequestMailer, type: :mailer, prep_admin_sets: true, prep_metadata_sources: true do
  describe 'access_change_request_email' do
    let(:admin_set) { AdminSet.first }
    let(:metadata_source) { MetadataSource.first }
    let(:parent_object) { FactoryBot.create(:parent_object, authoritative_metadata_source_id: metadata_source.id, admin_set_id: admin_set.id) }
    let(:permission_set) { FactoryBot.create(:permission_set) }
    let(:user) { FactoryBot.create(:user) }
    let(:approver_name) { user.first_name + ' ' + user.last_name }
    let(:access_change_request) do
      {
        approver_name: approver_name,
        permission_set_label: permission_set.label,
        admin_set_label: admin_set.label,
        parent_object_oid: parent_object.oid,
        new_visibility: 'Public'
      }
    end
    let(:mail) { described_class.with(access_change_request: access_change_request).access_change_request_email.deliver_now }

    it 'renders the expected fields' do
      expect(mail.subject).to eq 'DCS Object Visibility Update Request'
      expect(mail.to).to eq ['summer.shetenhelm@yale.edu']
      expect(mail.from).to eq ['do_not_reply@library.yale.edu']
      expect(mail.body.encoded).to include(approver_name)
      expect(mail.body.encoded).to include(permission_set.label)
      expect(mail.body.encoded).to include(admin_set.label)
      expect(mail.body.encoded).to include(parent_object.oid.to_s)
      expect(mail.body.encoded).to include('Public')
    end
  end
end

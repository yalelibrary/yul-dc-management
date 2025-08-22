# frozen_string_literal: true

require "rails_helper"

RSpec.describe NewPermissionRequestMailer, type: :mailer, prep_admin_sets: true, prep_metadata_sources: true do
  describe 'new_permission_request_email' do
    let(:admin_set) { AdminSet.first }
    let(:metadata_source) { MetadataSource.first }
    let(:parent_object) do
      FactoryBot.create(:parent_object, authoritative_metadata_source_id: metadata_source.id, admin_set_id: admin_set.id, oid: '2005512',
                                        ladybird_json: JSON.parse(File.read(File.join(fixture_path, "ladybird", "2005512.json"))))
    end
    let(:permission_set) { FactoryBot.create(:permission_set, key: 'xyz', label: 'Primary') }
    let(:permission_request) { FactoryBot.create(:permission_request, permission_set_id: permission_set.id, parent_object_id: parent_object.oid, user_note: 'message') }
    let(:user) { FactoryBot.create(:user) }
    let(:approver_name) { user.first_name + ' ' + user.last_name }
    let(:new_permission_request) do
      {
        permission_request_id: permission_request.id,
        permission_set_label: permission_set.label,
        parent_object_oid: parent_object.oid,
        parent_object_title: parent_object&.authoritative_json&.[]('title')&.first,
        requester_name: permission_request.permission_request_user.name,
        requester_email: permission_request.permission_request_user.email,
        requester_note: permission_request.user_note,
        approver_name: approver_name
      }
    end
    let(:mail) { described_class.with(new_permission_request: new_permission_request).new_permission_request_email(user.email).deliver_now }

    before do
      user.add_role(:approver, permission_set)
      stub_metadata_cloud('2005512')
      parent_object
    end

    it 'renders the expected fields' do
      expect(mail.subject).to eq "New Permission Request for #{permission_set.label}"
      expect(mail.to).to eq [user.email]
      expect(mail.from).to eq ['do_not_reply@yale.edu']
      expect(mail.body.encoded).to include(permission_set.label)
      expect(mail.body.encoded).to include(approver_name)
      expect(mail.body.encoded).to include(parent_object.oid.to_s)
      expect(mail.body.encoded).to include('The gold pen used by Lincoln to sign')
      expect(mail.body.encoded).to include("/catalog/#{parent_object.oid}")
      expect(mail.body.encoded).to include(permission_request.permission_request_user.name)
      expect(mail.body.encoded).to include(permission_request.permission_request_user.email)
      expect(mail.body.encoded).to include(permission_request.user_note)
      expect(mail.body.encoded).to include("permission_requests/#{permission_request.id}")
    end
  end
end

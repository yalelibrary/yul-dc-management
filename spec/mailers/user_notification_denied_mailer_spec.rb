# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserNotificationDeniedMailer, type: :mailer, prep_admin_sets: true, prep_metadata_sources: true do
  describe 'user_notification_denied_email' do
    let(:admin_set) { AdminSet.first }
    let(:metadata_source) { MetadataSource.first }
    let(:parent_object) { FactoryBot.create(:parent_object, authoritative_metadata_source_id: metadata_source.id, admin_set_id: admin_set.id) }
    let(:permission_set) { FactoryBot.create(:permission_set) }
    let(:request_user) { FactoryBot.create(:permission_request_user, sub: "sub 1", name: "name 1", netid: "netid", email: "email@example.com") }
    let(:permission_request) do
      FactoryBot.create(:permission_request, permission_set_id: permission_set.id, parent_object_id: parent_object.oid, user_note: 'message', permission_request_user: request_user)
    end
    let(:user_denied_notification) do
      {
        request_user_name: permission_request.permission_request_user.name,
        permission_set_label: permission_set.label,
        request_user_email: permission_request.permission_request_user.email,
        parent_object_title: "Title",
        parent_object_oid: parent_object.oid
      }
    end
    let(:user_denied_notification_kissinger) do
      {
        request_user_name: permission_request.permission_request_user.name,
        permission_set_label: "kiss",
        request_user_email: permission_request.permission_request_user.email,
        parent_object_title: "Title",
        parent_object_oid: parent_object.oid
      }
    end
    let(:mail) { described_class.with(user_notification: user_denied_notification).user_notification_denied_email.deliver_now }
    let(:kissinger_mail) { described_class.with(user_notification: user_denied_notification_kissinger).user_notification_denied_email.deliver_now }

    it 'renders the expected fields' do
      expect(mail.subject).to eq 'Your request to view Title has been denied'
      expect(mail.to).to eq ["email@example.com"]
      expect(mail.from).to eq ['do_not_reply@yale.edu']
      expect(mail.body.encoded).to include(permission_request.permission_request_user.name)
    end

    it 'sends email from correct address for a kissinger permission set' do
      expect(kissinger_mail.subject).to eq 'Your request to view Title has been denied'
      expect(kissinger_mail.to).to eq ["email@example.com"]
      expect(kissinger_mail.from).to eq ['kissingerpapers@gmail.com']
      expect(kissinger_mail.body.encoded).to include(permission_request.permission_request_user.name)
    end
  end
end

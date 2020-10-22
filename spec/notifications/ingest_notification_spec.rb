# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IngestNotification, prep_metadata_sources: true do
  let(:ladybird) { 1 }

  before do
    3.times do |_user|
      FactoryBot.create(:user)
    end
  end

  describe '#to_database' do
    it 'saves the type and params to the database' do
      IngestNotification.with(parent_object_id: '99977711', status: 'failed', reason: 'Metadata Cloud did not return json', batch_process_id: 'an_id').deliver(User.first)
      expect(Notification.last.type).to eq("IngestNotification")
      expect(Notification.last.params[:parent_object_id]).to eq("99977711")
      expect(Notification.last.params[:reason]).to eq("Metadata Cloud did not return json")
      expect(Notification.last.params[:status]).to eq("failed")
    end
  end

  describe '#deliver_all' do
    it 'can be delivered to all users' do
      expect(User.first.notifications.count).to eq(0)
      expect(User.second.notifications.count).to eq(0)
      expect(User.third.notifications.count).to eq(0)
      IngestNotification.with(parent_object_id: '99977722', status: 'failed', reason: 'Metadata Cloud did not return json', batch_process_id: 'an_id').deliver_all
      expect(User.first.notifications.count).to eq(1)
      expect(User.second.notifications.count).to eq(1)
      expect(User.third.notifications.count).to eq(1)
    end
  end

  describe '#message' do
    before do
      stub_metadata_cloud("2012143", "ladybird")
    end
    let(:parent_object) { FactoryBot.create(:parent_object, oid: '2012143', authoritative_metadata_source_id: ladybird) }

    it 'returns the oid, status and reason' do
      IngestNotification.with(parent_object_id: parent_object.id, status: 'failed', reason: 'Metadata Cloud did not return json', batch_process_id: 'an_id').deliver_all
      expect(Notification.last.to_notification.message).to eq("2012143 failed Metadata Cloud did not return json")
    end
  end
end

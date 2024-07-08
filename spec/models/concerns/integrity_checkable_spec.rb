# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IntegrityCheckable, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  let(:metadata_source) { MetadataSource.first }
  let(:admin_set) { AdminSet.first }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: '222', authoritative_metadata_source: metadata_source, admin_set: admin_set) }
  let(:child_object_one) { FactoryBot.create(:child_object, oid: '1', parent_object: parent_object) }
  let(:child_object_two) { FactoryBot.create(:child_object, oid: '356789', parent_object: parent_object, checksum: '78909999999999999') }
  let(:child_object_three) { FactoryBot.create(:child_object, oid: '456789', parent_object: parent_object, checksum: 'f3755c5d9e086b4522a0d3916e9a0bfcbd47564e') }

  around do |example|
    original_access_master_mount = ENV["ACCESS_MASTER_MOUNT"]
    ENV["ACCESS_MASTER_MOUNT"] = File.join(fixture_path, "images/ptiff_images")
    example.run
    ENV["ACCESS_MASTER_MOUNT"] = original_access_master_mount
  end

  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end

  context 'with less than the maximum number of child objects' do
    before do
      # file not present
      stub_request(:get, File.join(child_object_one.access_master_path)).to_return(status: 200, body: '')
      # file present but checksum does not match
      stub_request(:get, File.join(child_object_two.access_master_path)).to_return(status: 200, body: File.open(File.join(child_object_two.access_master_path)).read)
      # file present and checksum matches
      stub_request(:get, File.join(child_object_three.access_master_path)).to_return(status: 200, body: File.open(File.join(child_object_three.access_master_path)).read)
    end

    it 'reflects messages as expected' do
      expect { ChildObjectIntegrityCheckJob.new.perform }.to change { IngestEvent.count }.by(7)
      # rubocop:disable Layout/LineLength
      expect(child_object_one.events_for_batch_process(BatchProcess.first)[0].reason).to eq "Child Object: #{child_object_one.oid} - file not found at #{child_object_one.access_master_path} on #{ENV['ACCESS_MASTER_MOUNT']}.  Checksum could not be compared for the child object."
      expect(child_object_two.events_for_batch_process(BatchProcess.first)[0].reason).to eq "Child Object: #{child_object_two.oid} - file exists but the file's checksum [#{Digest::SHA1.file(child_object_two.access_master_path)}] does not match what is saved on the child object [#{child_object_two.checksum}]."
      expect(child_object_three.events_for_batch_process(BatchProcess.first)[0].reason).to eq "Child Object: #{child_object_three.oid} - checksum matches and file exists."
      # rubocop:enable Layout/LineLength
    end
  end

  context 'with more than the maximum number of child objects' do
    let(:total_child_objects) { 2500 }
    let(:limit) { 2000 }
    let(:parent_object_two) { FactoryBot.create(:parent_object, oid: '2228888333', authoritative_metadata_source: metadata_source, admin_set: admin_set) }
    let(:child_objects) { FactoryBot.create_list(:child_object, total_child_objects, parent_object: parent_object_two) }

    before do
      parent_object_two
      child_objects
    end

    it 'processes a maximum of 2000 child objects' do
      # Don't bother attaching the children, since we don't need messages from them:
      allow_any_instance_of(BatchProcess).to receive(:attach_item).and_return(nil)
      ChildObjectIntegrityCheckJob.new.perform
      expect(IngestEvent.last.reason).to eq "Integrity Check complete. #{limit} Child Object records reviewed."
    end
  end
end

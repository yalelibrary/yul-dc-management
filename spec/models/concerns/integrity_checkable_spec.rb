# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IntegrityCheckable, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  let(:metadata_source) { MetadataSource.first }
  let(:admin_set) { AdminSet.first }
  let(:parent_object_one) { FactoryBot.create(:parent_object, oid: '111', child_object_count: 1, authoritative_metadata_source: metadata_source, admin_set: admin_set) }
  let(:parent_object_two) { FactoryBot.create(:parent_object, oid: '222', child_object_count: 1, authoritative_metadata_source: metadata_source, admin_set: admin_set) }
  let(:parent_object_three) { FactoryBot.create(:parent_object, oid: '333', child_object_count: 1, authoritative_metadata_source: metadata_source, admin_set: admin_set) }
  let(:parent_object_four) { FactoryBot.create(:parent_object, oid: '444', child_object_count: 1, authoritative_metadata_source: metadata_source, admin_set: admin_set) }

  let(:child_object_one) { FactoryBot.create(:child_object, oid: '1', parent_object: parent_object_one, sha256_checksum: '08a76890fcf6c7f9fa27a1191a53dcfdb198461b1ffff9435198b7b86a6d392a') }
  let(:child_object_two) { FactoryBot.create(:child_object, oid: '356789', parent_object: parent_object_two, md5_checksum: '1c7ebd11e1060b4e2c9476950086556bz') }
  let(:child_object_three) do
    FactoryBot.create(:child_object, oid: '456789', parent_object: parent_object_three, file_size: 1234,
                                     sha512_checksum: 'd6e3926fbe14fedbf3a568b6a5dbdb3e8b2312f217daa460a743559d41a688af4a7c701e7bac908fc7e3fd51c505fa01dad9eee96fcfd2666e92c648249edf02')
  end
  let(:child_object_four) { FactoryBot.create(:child_object, oid: '567890', parent_object: parent_object_four, file_size: 1234, checksum: 'f3755c5d9e086b4522a0d3916e9a0bfcbd47564ef') }

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
      # file present but file size is less than 0
      stub_request(:get, File.join(child_object_two.access_master_path)).to_return(status: 200, body: File.open(File.join(child_object_two.access_master_path)).read)
      # file present and checksum matches
      stub_request(:get, File.join(child_object_three.access_master_path)).to_return(status: 200, body: File.open(File.join(child_object_three.access_master_path)).read)
      # file present and file size greater than 0 but checksum does not match
      stub_request(:get, File.join(child_object_four.access_master_path)).to_return(status: 200, body: File.open(File.join(child_object_three.access_master_path)).read)
    end

    it 'reflects messages as expected' do
      expect { ChildObjectIntegrityCheckJob.new.perform }.to change { IngestEvent.count }.by(9)
      # rubocop:disable Layout/LineLength
      expect(child_object_one.events_for_batch_process(BatchProcess.first)[0].reason).to eq "Child Object: #{child_object_one.oid} - file not found at #{child_object_one.access_master_path} on #{ENV['ACCESS_MASTER_MOUNT']}."
      expect(child_object_two.events_for_batch_process(BatchProcess.first)[0].reason).to eq "Child Object: #{child_object_two.oid} - has a file size of 0. Please verify image for Child Object: #{child_object_two.oid}."
      expect(child_object_three.events_for_batch_process(BatchProcess.first)[0].reason).to eq "Child Object: #{child_object_three.oid} - file exists and checksum matches."
      expect(child_object_four.events_for_batch_process(BatchProcess.first)[0].reason).to eq "The Child Object: #{child_object_four.oid} - has a checksum mismatch. The checksum of the image file saved to this child oid does not match the checksum of the image file in the database. This may mean that the image has been corrupted. Please verify integrity of image for Child Object: #{child_object_four.oid} - by manually comparing the checksum values and update record as necessary."
      # rubocop:enable Layout/LineLength
    end
  end

  context 'with more than the maximum number of child objects' do
    let(:total_parent_objects) { 2500 }
    let(:limit) { 2000 }
    let(:parent_objects) { FactoryBot.build_list(:parent_object_with_random_oid, total_parent_objects, authoritative_metadata_source: metadata_source, admin_set: admin_set, child_object_count: 1) }
    let(:child_object) { FactoryBot.create(:child_object, parent_object: parent_objects[0]) }

    before do
      not_clause = double
      where = double
      limit_mock = double
      set_mock = double
      allow(where).to receive(:not).and_return(not_clause)
      allow(not_clause).to receive(:and).and_return(set_mock)
      allow(set_mock).to receive(:limit).with(limit).and_return(limit_mock)
      allow(limit_mock).to receive(:order).and_return(parent_objects[0..1999])
      allow(ParentObject).to receive(:where).and_return(where)
    end

    it 'processes a maximum of 2000 child objects' do
      allow_any_instance_of(ParentObject).to receive(:child_objects).and_return([child_object])
      # Don't bother attaching the children, since we don't need messages from them:
      allow_any_instance_of(BatchProcess).to receive(:attach_item).and_return(nil)
      ChildObjectIntegrityCheckJob.new.perform
      expect(IngestEvent.last.reason).to eq "Integrity Check complete. #{limit} Child Object records reviewed."
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetupMetadataJob, type: :job, prep_admin_sets: true, prep_metadata_sources: true do
  before do
    allow(GoodJob).to receive(:preserve_job_records).and_return(true)
    ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
  end
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:parent_object) { FactoryBot.create(:parent_object, admin_set: AdminSet.first, authoritative_metadata_source: MetadataSource.first) }
  let(:metadata_job) { SetupMetadataJob.new }
  let(:non_test_env) { "production" }

  it 'enqueues the job successfully' do
    active_job = described_class.perform_later(parent_object, batch_process)
    expect(active_job.instance_variable_get(:@successfully_enqueued)).to be true
  end

  context 'job fails' do
    it 'notifies on save failure' do
      allow(parent_object).to receive(:default_fetch).and_raise('boom!')
      expect(parent_object).to receive(:processing_event)
      expect { metadata_job.perform(parent_object, batch_process) }.to raise_error('boom!')
    end

    it 'notifies if all images are not present' do
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(SetupMetadataJob).to receive(:check_mets_images).and_return(false)
      # rubocop:enable RSpec/AnyInstance
      expect(parent_object).to receive(:processing_event).with("SetupMetadataJob failed to find all images.", "failed").once
      metadata_job.perform(parent_object, batch_process)
    end
  end

  context 'metadata fetch skipping for Voyager and Sierra' do
    let(:sierra_source) { MetadataSource.find_by(metadata_cloud_name: 'sierra') || FactoryBot.create(:metadata_source, metadata_cloud_name: 'sierra') }
    let(:ils_source) { MetadataSource.find_by(metadata_cloud_name: 'ils') || FactoryBot.create(:metadata_source, metadata_cloud_name: 'ils') }
    let(:alma_source) { MetadataSource.find_by(metadata_cloud_name: 'alma') || FactoryBot.create(:metadata_source, metadata_cloud_name: 'alma') }

    it 'skips metadata fetch for Sierra data source' do
      parent_object.authoritative_metadata_source = sierra_source
      parent_object.save!

      allow(parent_object).to receive(:processing_event).and_call_original
      allow(metadata_job).to receive(:setup_child_object_jobs)

      metadata_job.perform(parent_object, batch_process)

      expect(parent_object).to have_received(:processing_event).with("Metadata fetch skipped for sierra data source", "metadata-fetch-skipped")
    end

    it 'skips metadata fetch for ILS (Voyager) data source' do
      parent_object.authoritative_metadata_source = ils_source
      parent_object.save!

      allow(parent_object).to receive(:processing_event).and_call_original
      allow(metadata_job).to receive(:setup_child_object_jobs)

      metadata_job.perform(parent_object, batch_process)

      expect(parent_object).to have_received(:processing_event).with("Metadata fetch skipped for ils data source", "metadata-fetch-skipped")
    end

    it 'does not skip metadata fetch for other data sources like Alma' do
      parent_object.authoritative_metadata_source = alma_source
      parent_object.save!

      expect(parent_object).not_to receive(:processing_event).with(/Metadata fetch skipped/, "metadata-fetch-skipped")
      allow(metadata_job).to receive(:setup_child_object_jobs)

      metadata_job.perform(parent_object, batch_process)
    end

    it 'continues with normal job flow when metadata fetch is skipped' do
      parent_object.authoritative_metadata_source = sierra_source
      parent_object.save!

      allow(parent_object).to receive(:processing_event).and_call_original
      allow(metadata_job).to receive(:setup_child_object_jobs).and_call_original

      metadata_job.perform(parent_object, batch_process)

      expect(parent_object).to have_received(:processing_event).with("Metadata fetch skipped for sierra data source", "metadata-fetch-skipped")
      expect(metadata_job).to have_received(:setup_child_object_jobs).with(parent_object, batch_process)
    end
  end

  context 'Ladybird metadata fetch environment gating' do
    let(:ladybird_source) { MetadataSource.find_by(metadata_cloud_name: 'ladybird') || FactoryBot.create(:metadata_source) }

    before do
      parent_object.authoritative_metadata_source = ladybird_source
      parent_object.save!
      stub_metadata_cloud(parent_object.oid.to_s, "ladybird")
    end

    context 'in test environment' do
      it 'performs the Ladybird fetch' do
        allow(parent_object).to receive(:processing_event).and_call_original
        allow(metadata_job).to receive(:setup_child_object_jobs)

        metadata_job.perform(parent_object, batch_process)

        expect(parent_object).not_to have_received(:processing_event).with(/Ladybird is not available/, "failed")
        expect(parent_object.ladybird_json).not_to be_nil
      end
    end

    context 'in non-test environment' do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with("RAILS_ENV").and_return(non_test_env)
        allow(parent_object).to receive(:processing_event).and_call_original
      end

      it 'fails with a descriptive message' do
        metadata_job.perform(parent_object, batch_process)

        expect(parent_object).to have_received(:processing_event).with(
          "Metadata fetch failed: Ladybird is not available as a metadata source in this environment. Please update the authoritative metadata source.", "failed"
        )
        expect(parent_object.ladybird_json).to be_nil
      end

      it 'does not continue job processing' do
        allow(metadata_job).to receive(:setup_child_object_jobs)

        metadata_job.perform(parent_object, batch_process)

        expect(metadata_job).not_to have_received(:setup_child_object_jobs)
      end
    end
  end

  context 'ArchiveSpace Ladybird fetch environment gating' do
    let(:aspace_source) { MetadataSource.find_by(metadata_cloud_name: 'aspace') || FactoryBot.create(:metadata_source_aspace) }
    let(:parent_object_without_aspace_uri) do
      FactoryBot.create(:parent_object, oid: "2005512", admin_set: AdminSet.first,
                                        authoritative_metadata_source: aspace_source, aspace_uri: nil)
    end

    before do
      stub_metadata_cloud("2005512", "ladybird")
      stub_metadata_cloud("AS-2005512", "aspace")
    end

    context 'in test environment' do
      it 'fetches Ladybird data when aspace_uri is blank' do
        allow(parent_object_without_aspace_uri).to receive(:processing_event).and_call_original
        fetch_result = parent_object_without_aspace_uri.default_fetch

        expect(parent_object_without_aspace_uri.ladybird_json).not_to be_nil
        expect(fetch_result).to be_truthy
      end
    end

    context 'in non-test environment' do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with("RAILS_ENV").and_return(non_test_env)
      end

      it 'skips Ladybird fetch when aspace_uri is blank' do
        allow(parent_object_without_aspace_uri).to receive(:processing_event).and_call_original
        parent_object_without_aspace_uri.default_fetch

        expect(parent_object_without_aspace_uri.ladybird_json).to be_nil
      end
    end
  end
end

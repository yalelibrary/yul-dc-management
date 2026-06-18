# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreatePreservicaChildrenJob, type: :job, prep_admin_sets: true, prep_metadata_sources: true do
  def run_create_preservica_children_retry_jobs
    GoodJob.perform_inline
    3.times do
      scheduled_jobs = GoodJob::Job.where(job_class: 'CreatePreservicaChildrenJob')
                                   .where(finished_at: nil)
                                   .where("scheduled_at > ?", Time.current)
      break if scheduled_jobs.none?

      scheduled_jobs.find_each { |job| job.update!(scheduled_at: Time.current) }
      GoodJob.perform_inline
    end
  end

  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:parent_object) do
    FactoryBot.create(:parent_object,
                      oid: 2_034_600,
                      admin_set: AdminSet.find_by(key: 'brbl'),
                      authoritative_metadata_source: MetadataSource.first,
                      digital_object_source: "Preservica",
                      preservica_uri: "/preservica/api/entity/structural-objects/7fe35e8c-c21a-444a-a2e2-e3c926b519c5",
                      preservica_representation_type: "Access")
  end
  let(:job) { described_class.new }

  around do |example|
    preservica_host = ENV['PRESERVICA_HOST']
    preservica_creds = ENV['PRESERVICA_CREDENTIALS']
    access_host = ENV['ACCESS_PRIMARY_MOUNT']

    ENV['PRESERVICA_HOST'] = 'testpreservica'
    ENV['PRESERVICA_CREDENTIALS'] = '{"brbl": {"username":"xxxxx", "password":"xxxxx"}}'
    ENV['ACCESS_PRIMARY_MOUNT'] = File.join('spec', 'fixtures', 'images', 'access_primaries')

    example.run
  ensure
    ENV['PRESERVICA_HOST'] = preservica_host
    ENV['PRESERVICA_CREDENTIALS'] = preservica_creds
    ENV['ACCESS_PRIMARY_MOUNT'] = access_host
  end

  before do
    stub_preservica_login
    stub_preservica_fixtures_set_of_three_changing_generation
    stub_preservica_tifs_set_of_three
  end

  it 'enqueues the job successfully' do
    active_job = described_class.perform_later(parent_object, batch_process)
    expect(active_job.instance_variable_get(:@successfully_enqueued)).to be true
  end

  it 'uses the default queue' do
    expect(described_class.new.queue_name).to eq('default')
  end

  it "has correct priority" do
    create_preservica_children_job = described_class.new
    expect(create_preservica_children_job.default_priority).to eq(40)
  end

  context 'when performing' do
    before do
      allow(parent_object).to receive(:create_child_records)
      allow(parent_object).to receive(:save!)
      allow(parent_object).to receive(:reload)
      allow(parent_object).to receive(:gather_technical_image_metadata)
      allow(parent_object).to receive(:processing_event)
      allow(parent_object).to receive(:child_objects).and_return([])
      allow(parent_object).to receive(:needs_a_manifest?).and_return(false)
    end

    it 'calls create_child_records on the parent object' do
      job.perform(parent_object, batch_process)
      expect(parent_object).to have_received(:create_child_records)
    end

    it 'saves and reloads the parent object' do
      job.perform(parent_object, batch_process)
      expect(parent_object).to have_received(:save!)
      expect(parent_object).to have_received(:reload)
    end

    it 'gathers technical image metadata' do
      job.perform(parent_object, batch_process)
      expect(parent_object).to have_received(:gather_technical_image_metadata)
    end

    it 'logs a child-records-created event' do
      job.perform(parent_object, batch_process)
      expect(parent_object).to have_received(:processing_event).with("Child object records have been created", "child-records-created")
    end
  end

  it 'logs failed processing event on first retryable failure' do
    allow(parent_object).to receive(:create_child_records).and_raise(RuntimeError, 'Something went wrong')
    allow(parent_object).to receive(:processing_event)
    allow(parent_object).to receive(:child_objects).and_return([])
    allow(parent_object).to receive(:needs_a_manifest?).and_return(false)

    expect do
      described_class.perform_now(parent_object, batch_process)
    end.not_to raise_error

    expect(parent_object).to have_received(:processing_event)
      .with('Preservica child creation failed: Something went wrong', 'failed')
  end

  it 'logs retry callback message when retries are exhausted' do
    with_good_job_external_mode do
      GoodJob::Job.where(job_class: 'CreatePreservicaChildrenJob').delete_all
      batch_connection = batch_process.batch_connections.find_or_create_by!(connectable: parent_object)
      parent_object.current_batch_process = batch_process
      parent_object.current_batch_connection = batch_connection

      allow_any_instance_of(ParentObject).to receive(:create_child_records)
        .and_raise(PreservicaImageService::PreservicaImageServiceNetworkError.new('Net::ReadTimeout', 'sample.com/uri'))
      allow_any_instance_of(ParentObject).to receive(:gather_technical_image_metadata)
      allow_any_instance_of(ParentObject).to receive(:child_objects).and_return([])
      allow_any_instance_of(ParentObject).to receive(:needs_a_manifest?).and_return(false)
      allow(ParentObject).to receive(:find_by).with(oid: parent_object.oid).and_return(parent_object)

      described_class.perform_later(parent_object, batch_process, batch_connection)
      run_create_preservica_children_retry_jobs

      reasons = parent_object.reload
                             .events_for_batch_process(batch_process)
                             .where(status: 'retry')
                             .pluck(:reason)

      expect(reasons).to include('Retrying Child Object Creation - Request error Net::ReadTimeout for sample.com/uri')
    end
  end

  it 'does not retry on PreservicaImageServiceError' do
    error = PreservicaImageService::PreservicaImageServiceError.new('No matching representation found in Preservica', '/preservica/api/entity')
    allow(parent_object).to receive(:create_child_records).and_raise(error)
    allow(parent_object).to receive(:processing_event)
    allow(parent_object).to receive(:child_objects).and_return([])
    allow(parent_object).to receive(:needs_a_manifest?).and_return(false)

    expect do
      described_class.perform_now(parent_object, batch_process)
    end.to raise_error(PreservicaImageService::PreservicaImageServiceError)

    expect(parent_object).to have_received(:processing_event)
      .with("Preservica child creation failed: #{error.message}", 'failed')
    expect(parent_object).not_to have_received(:processing_event)
      .with(a_string_starting_with('Retrying Child Object Creation - Request error'), 'retry')
  end
end

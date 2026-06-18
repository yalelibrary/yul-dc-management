# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Preservica::PreservicaObject, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  def execute_retry_job
    yield
    GoodJob.perform_inline
    GoodJob::Job.where(job_class: 'CreatePreservicaChildrenJob')
                .where(finished_at: nil)
                .where("scheduled_at > ?", Time.current)
                .find_each { |job| job.update!(scheduled_at: Time.current) }
    GoodJob.perform_inline
  end

  subject(:batch_process) { BatchProcess.new }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl') }
  let(:admin_set_sml) { FactoryBot.create(:admin_set, key: 'sml') }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:preservica_parent_with_children) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_paths[0], "csv", "preservica", "preservica_parent_with_children.csv")) }

  around do |example|
    preservica_host = ENV['PRESERVICA_HOST']
    preservica_creds = ENV['PRESERVICA_CREDENTIALS']
    ENV['PRESERVICA_HOST'] = "testpreservica"
    ENV['PRESERVICA_CREDENTIALS'] = '{"brbl": {"username":"xxxxx", "password":"xxxxx"}}'
    access_host = ENV['ACCESS_PRIMARY_MOUNT']
    ENV['ACCESS_PRIMARY_MOUNT'] = File.join("spec", "fixtures", "images", "access_primaries")
    perform_enqueued_jobs do
      example.run
    end
    ENV['PRESERVICA_HOST'] = preservica_host
    ENV['PRESERVICA_CREDENTIALS'] = preservica_creds
    ENV['ACCESS_PRIMARY_MOUNT'] = access_host
  end

  before do
    login_as(:user)
    batch_process.user_id = user.id
    stub_pdfs
    stub_preservica_aspace_single
    stub_preservica_login
    fixtures = %w[preservica/api/entity/structural-objects/7fe35e8c-c21a-444a-a2e2-e3c926b519c5/children
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3r/representations
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3r/representations/Access
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3r/representations/Preservation
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1/bitstreams/1
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3d/representations
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3d/representations/Access
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3d/representations/Preservation
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1/bitstreams/1
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f44/representations
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f44/representations/Access
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f44/representations/Preservation
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1/bitstreams/1]

    fixtures.each do |fixture|
      stub_request(:get, "https://test#{fixture}").to_return(
        status: 200, body: File.open(File.join(fixture_paths[0], "#{fixture}.xml"))
      )
    end

    stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1/bitstreams/1/content").to_return(
      status: 404, body: "Content object bitstreams cannot be downloaded."
    ).then.to_return(
      status: 200, body: File.open(File.join(fixture_paths[0], "preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1/bitstreams/1/content.tif"))
    )
    stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1/bitstreams/1/content").to_return(
      status: 200, body: File.open(File.join(fixture_paths[0], "preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1/bitstreams/1/content.tif"))
    )
    stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1/bitstreams/1/content").to_return(
      status: 200, body: File.open(File.join(fixture_paths[0], "preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1/bitstreams/1/content.tif"))
    )
  end

  context 'user with permission' do
    before do
      ActiveJob::Base.queue_adapter = GoodJob::Adapter.new(execution_mode: :external)
      user.add_role(:editor, admin_set)
      login_as(:user)
    end

    it 'can recognize when child is not found in preservica and retry' do
      allow(S3Service).to receive(:s3_exists?).and_return(false)
      execute_retry_job do
        batch_process.file = preservica_parent_with_children
        batch_process.save
      end
      po_first = ParentObject.first
      retry_reasons = po_first.events_for_batch_process(batch_process).map(&:reason)
      good_job = GoodJob::Job.where("serialized_params -> 'arguments' @> ?", [{ "_aj_globalid" => "gid://yul-dc-management/ParentObject/#{po_first.id}" }].to_json)
                            .where(job_class: "CreatePreservicaChildrenJob")
                            .order(created_at: :desc)
                            .first
      expect(retry_reasons).to include("Preservica child creation failed: Request error 404 Content object bitstreams cannot be downloaded.")
      expect(good_job).not_to be_nil
      related_jobs = GoodJob::Job.where("serialized_params -> 'arguments' @> ?", [{ "_aj_globalid" => "gid://yul-dc-management/ParentObject/#{po_first.id}" }].to_json)
                 .where(job_class: "CreatePreservicaChildrenJob")
      retry_scheduled = related_jobs.where("scheduled_at > created_at").exists? ||
                        related_jobs.where.not(retried_good_job_id: nil).exists? ||
                        GoodJob::Job.where(retried_good_job_id: related_jobs.select(:id)).exists?
      expect(retry_scheduled).to be(true)
      expect(po_first.last_preservica_update).not_to eq nil
      expect(po_first.child_objects.count).to eq 3
      expect(po_first.child_object_count).to eq 3
      expect(po_first.child_objects[0].preservica_content_object_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486"
      expect(po_first.child_objects[1].preservica_content_object_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489"
      expect(po_first.child_objects[2].preservica_content_object_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487"
    end
  end
end

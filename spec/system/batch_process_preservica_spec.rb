# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :system, prep_metadata_sources: true, prep_admin_sets: true, solr: true do
  subject(:batch_process) { BatchProcess.new }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl') }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:preservica_sync) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_sync.csv")) }
  let(:preservica_parent_with_two_children) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_with_two_children.csv")) }
  let(:first_tif) { "spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif" }
  let(:second_tif) { "spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif" }
  let(:third_tif) { "spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif" }

  around do |example|
    preservica_host = ENV['PRESERVICA_HOST']
    preservica_creds = ENV['PRESERVICA_CREDENTIALS']
    ENV['PRESERVICA_HOST'] = "testpreservica"
    ENV['PRESERVICA_CREDENTIALS'] = '{"brbl": {"username":"xxxxx", "password":"xxxxx"}}'
    access_host = ENV['ACCESS_MASTER_MOUNT']
    ENV['ACCESS_MASTER_MOUNT'] = File.join("spec", "fixtures", "images", "access_masters")
    perform_enqueued_jobs do
      example.run
    end
    ENV['PRESERVICA_HOST'] = preservica_host
    ENV['PRESERVICA_CREDENTIALS'] = preservica_creds
    ENV['ACCESS_MASTER_MOUNT'] = access_host
  end

  before do
    login_as user
    batch_process.user_id = user.id
    stub_preservica_aspace_single
    stub_preservica_login

    # fixtures for failed batch process
    fixtures = %w[preservica/api/entity/structural-objects/7fe35e8c-c21a-444a-a2e2-e3c926b519c6/children
                  preservica/api/entity/information-objects/b31ba07e-88ce-4558-8e89-81cff9630799/representations
                  preservica/api/entity/information-objects/b31ba07e-88ce-4558-8e89-81cff9630799/representations/Access
                  preservica/api/entity/information-objects/b31ba07e-88ce-4558-8e89-81cff9630799/representations/Preservation
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1/bitstreams/1
                  preservica/api/entity/information-objects/b31ba07e-88ce-4558-8e89-81cff9630899/representations
                  preservica/api/entity/information-objects/b31ba07e-88ce-4558-8e89-81cff9630899/representations/Access
                  preservica/api/entity/information-objects/b31ba07e-88ce-4558-8e89-81cff9630899/representations/Preservation
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1/bitstreams/1]

    fixtures.each do |fixture|
      stub_request(:get, "https://test#{fixture}").to_return(
        status: 200, body: File.open(File.join(fixture_path, "#{fixture}.xml"))
      ).then.to_return(status: 500, body: 'mock error')
    end
    stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1/bitstreams/1/content").to_return(
      status: 200, body: File.open(File.join(fixture_path, "preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1/bitstreams/1/content.tif"), 'rb')
    ).then.to_return(status: 500, body: 'mock error')
    stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1/bitstreams/1/content").to_return(
      status: 200, body: File.open(File.join(fixture_path, "preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1/bitstreams/1/content.tif"), 'rb')
    ).then.to_return(status: 500, body: 'mock error')
  end

  context 'user with edit permission' do
    before do
      user.add_role(:editor, admin_set)
      login_as user
    end

    it 'can recognize and report a failure' do
      # mock a PreservicaImageServiceNetworkError - see tif stubbing

      # create the parent
      expect do
        batch_process.file = preservica_parent_with_two_children
        batch_process.save
      end.to change { ParentObject.count }.from(0).to(1)

      # sync parent
      sync_batch_process = BatchProcess.new(batch_action: 'resync with preservica', user: user)
      expect do
        sync_batch_process.file = preservica_sync
        sync_batch_process.save!
      end.not_to change { ParentObject.count }

      # report out the failure
      visit batch_process_path(batch_process.id)
      expect(page).to have_content 'Batch failed'
    end
  end
end

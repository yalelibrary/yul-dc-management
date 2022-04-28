# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Preservica::PreservicaObject, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  subject(:batch_process) { BatchProcess.new }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl') }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:preservica_parent_with_children) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_with_children.csv")) }
  let(:preservica_sync) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_sync.csv")) }
  let(:first_tif) { "spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif" }
  let(:second_tif) { "spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif" }
  let(:third_tif) { "spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif" }
  let(:fourth_tif) { "spec/fixtures/images/access_masters/00/04/20/00/00/00/200000004.tif" }
  let(:fifth_tif) { "spec/fixtures/images/access_masters/00/05/20/00/00/00/200000005.tif" }
  let(:sixth_tif) { "spec/fixtures/images/access_masters/00/06/20/00/00/00/200000006.tif" }

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
    login_as(:user)
    batch_process.user_id = user.id
    stub_metadata_cloud("AS-200000000", "aspace")
    stub_request(:post, "https://testpreservica/api/accesstoken/login").to_return(status: 200, body: '{"token":"test"}')
    stub_request(:post, "https://testpreservica/api/accesstoken/refresh").to_return(status: 200, body: '{"token":"test"}')
    fixtures = %w[preservica/api/entity/structural-objects/7fe35e8c-c21a-444a-a2e2-e3c926b519c5/children
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3r/representations
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3r/representations/Access-2
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3r/representations/Preservation-1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1/bitstreams/1
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3d/representations
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3d/representations/Access-2
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3d/representations/Preservation-1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1/bitstreams/1
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f44/representations
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f44/representations/Access-2
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f44/representations/Preservation-1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1/bitstreams/1]

    changing_fixtures = %w[preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1]

    fixtures.each do |fixture|
      stub_request(:get, "https://test#{fixture}").to_return(
        status: 200, body: File.open(File.join(fixture_path, "#{fixture}.xml"))
      )
    end

    changing_fixtures.each do |fixture|
      stub_request(:get, "https://test#{fixture}").to_return(
        status: 200, body: File.open(File.join(fixture_path, "#{fixture}.xml"))
      ).times(2).then.to_return(
        status: 200, body: File.open(File.join(fixture_path, "#{fixture}_new.xml"))
      )
    end

    stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1/bitstreams/1/content").to_return(
      status: 200, body: File.open(File.join(fixture_path, "preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1/bitstreams/1/content.tif"), 'rb')
    )
    stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1/bitstreams/1/content").to_return(
      status: 200, body: File.open(File.join(fixture_path, "preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1/bitstreams/1/content.tif"), 'rb')
    )
    stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1/bitstreams/1/content").to_return(
      status: 200, body: File.open(File.join(fixture_path, "preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1/bitstreams/1/content.tif"), 'rb')
    )
  end

  context 'user with edit permission' do
    before do
      user.add_role(:editor, admin_set)
      login_as(:user)
    end

    it 'can recognize when there is a new generation in preservica' do
      File.delete(first_tif) if File.exist?(first_tif)
      File.delete(second_tif) if File.exist?(second_tif)
      File.delete(third_tif) if File.exist?(third_tif)
      File.delete(fourth_tif) if File.exist?(fourth_tif)
      File.delete(fifth_tif) if File.exist?(fifth_tif)
      File.delete(sixth_tif) if File.exist?(sixth_tif)

      allow(S3Service).to receive(:s3_exists?).and_return(false)
      expect(File.exist?(first_tif)).to be false
      expect(File.exist?(second_tif)).to be false
      expect(File.exist?(third_tif)).to be false
      expect(File.exist?(fourth_tif)).to be false
      expect(File.exist?(fifth_tif)).to be false
      expect(File.exist?(sixth_tif)).to be false
      expect do
        batch_process.file = preservica_parent_with_children
        batch_process.save
      end.to change { ChildObject.count }.from(0).to(3)
      expect(File.exist?(first_tif)).to be true
      expect(File.exist?(second_tif)).to be true
      expect(File.exist?(third_tif)).to be true

      po_first = ParentObject.first
      co_first = po_first.child_objects.first
      expect(po_first.last_preservica_update).not_to be nil
      expect(co_first.preservica_generation_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1"
      expect(co_first.preservica_bitstream_uri).to eq "/home/app/webapp/spec/fixtures/preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1/bitstreams/1"
      expect(co_first.ptiff_conversion_at.present?).to be_truthy
      expect(po_first.child_objects.count).to eq 3

      sync_batch_process = BatchProcess.new(batch_action: 'sync from preservica', user: user)
      expect do
        sync_batch_process.file = preservica_sync
        sync_batch_process.save!
      end.not_to change { ChildObject.count }
      # downloads new tif to pairtree
      expect(File.exist?(fourth_tif)).to be true
      expect(File.exist?(fifth_tif)).to be true
      expect(File.exist?(sixth_tif)).to be true

      po_first = ParentObject.first
      co_first = po_first.child_objects.first
      expect(co_first.preservica_generation_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1_new"
      expect(co_first.preservica_bitstream_uri).to eq "/home/app/webapp/spec/fixtures/preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1_new/bitstreams/1"

      File.delete(first_tif) if File.exist?(first_tif)
      File.delete(second_tif) if File.exist?(second_tif)
      File.delete(third_tif) if File.exist?(third_tif)
      File.delete(fourth_tif) if File.exist?(fourth_tif)
      File.delete(fifth_tif) if File.exist?(fifth_tif)
      File.delete(sixth_tif) if File.exist?(sixth_tif)
    end
  end
end

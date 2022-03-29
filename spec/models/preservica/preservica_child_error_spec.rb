# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Preservica::PreservicaObject, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  subject(:batch_process) { BatchProcess.new }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl') }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:preservica_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent.csv")) }
  let(:preservica_parent_with_children) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_with_children.csv")) }
  let(:preservica_parent_no_structural) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_no_structural.csv")) }
  let(:preservica_parent_no_information_pattern_1) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_no_information_pattern_1.csv")) }
  let(:preservica_parent_no_information_pattern_2) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_no_information_pattern_2.csv")) }
  let(:preservica_parent_no_representation_pattern_1) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_no_representation_pattern_1.csv")) }
  let(:preservica_parent_no_representation_pattern_2) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_no_representation_pattern_2.csv")) }
  let(:preservica_parent_no_generation_pattern_1) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_no_generation_pattern_1.csv")) }
  let(:preservica_parent_no_generation_pattern_2) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_no_generation_pattern_2.csv")) }
  let(:preservica_parent_checksum_mismatch_pattern_1) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_checksum_mismatch_pattern_1.csv")) }
  let(:preservica_parent_checksum_mismatch_pattern_2) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_checksum_mismatch_pattern_2.csv")) }
  let(:preservica_parent_no_sha_pattern_1) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_no_sha_pattern_1.csv")) }
  let(:preservica_parent_no_sha_pattern_2) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_no_sha_pattern_2.csv")) }

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
    user.add_role(:editor, admin_set)
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
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1
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
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1/bitstreams/1
                  preservica/api/entity/structural-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e4b/children
                  preservica/api/entity/structural-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e3a/children
                  preservica/api/entity/information-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e3c/representations
                  preservica/api/entity/information-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e3c/representations/Access-2
                  preservica/api/entity/information-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e3c/representations/Preservation-1
                  preservica/api/entity/information-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e7e/representations
                  preservica/api/entity/information-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e7e/representations/Access-2
                  preservica/api/entity/information-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e7e/representations/Preservation-1
                  preservica/api/entity/structural-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e9z/children
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e5z/representations
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e5z/representations/Preservation-1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b900/generations
                  preservica/api/entity/structural-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e0a/children
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a4d4a/representations
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a4d4a/representations/Preservation-1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157c600/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157c600/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157c600/generations/1/bitstreams/1
                  preservica/api/entity/structural-objects/2e42a2bb-8953-41b6-bcc3-1a19c867u8y/children
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a8y7u/representations
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a8y7u/representations/Preservation-1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157d799/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157d799/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157d799/generations/1/bitstreams/1]

    fixtures.each do |fixture|
      stub_request(:get, "https://test#{fixture}").to_return(
        status: 200, body: File.open(File.join(fixture_path, "#{fixture}.xml"))
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

  it 'can create child objects' do
    File.delete("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif") if File.exist?("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif")
    File.delete("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif") if File.exist?("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif")
    File.delete("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif") if File.exist?("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif")

    allow(S3Service).to receive(:s3_exists?).and_return(false)
    expect(File.exist?("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif")).to be false
    expect(File.exist?("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif")).to be false
    expect(File.exist?("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif")).to be false
    expect do
      batch_process.file = preservica_parent_with_children
      batch_process.save
    end.to change { ChildObject.count }.from(0).to(3)
    po_first = ParentObject.first
    co_first = ChildObject.first
    expect(co_first.oid).to be 200_000_001
    expect(co_first.parent_object_oid).to be 200_000_000
    expect(co_first.order).to be 1
    co_last = ChildObject.last
    expect(co_last.order).to be 3
    expect(po_first.last_preservica_update).not_to be nil
    expect(co_first.preservica_content_object_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486"
    expect(co_first.preservica_generation_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1"
    expect(co_first.preservica_bitstream_uri).to eq "/home/app/webapp/spec/fixtures/preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1/bitstreams/1"
    expect(co_first.sha512_checksum).to eq "1932c08c4670d5010fac6fa363ad5d9be7a4e7d743757ba5eefbbe8e3f9b2fb89b1604c1e527cfae6f47a91a60845268e91d2723aa63a90dd4735f75017569f7"
    expect(File.exist?("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif")).to be true
    expect(File.exist?("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif")).to be true
    expect(File.exist?("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif")).to be true
    expect(co_first.ptiff_conversion_at.present?).to be_truthy
    File.delete("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif") if File.exist?("spec/fixtures/images/access_masters/00/01/20/00/00/00/200000001.tif")
    File.delete("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif") if File.exist?("spec/fixtures/images/access_masters/00/02/20/00/00/00/200000002.tif")
    File.delete("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif") if File.exist?("spec/fixtures/images/access_masters/00/03/20/00/00/00/200000003.tif")
  end

  # Potential Errors
  # loss of connection / authorization
  # structural object doesn't exist
  # information object doesn't exist
  # representation does not have preservation_representation_name that matches what's provided in the csv
  # no active generations
  # bitstream checksum mismatch
  # if no sha512 is found

  it 'can send an error when not logged in' do
    stub_request(:post, "https://testpreservica/api/accesstoken/login").to_return(status: 403, body: '{"token":"access denied"}')
    expect do
      batch_process.file = preservica_parent_with_children
      batch_process.save
      expect(batch_process.batch_ingest_events.count).to eq(1)
      expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] Unable to log in to Preservica for /preservica/api/entity/structural-objects/7fe35e8c-c21a-444a-a2e2-e3c926b519c5.")
    end.to change { ChildObject.count }.by(0)
  end

  it 'can send an error when there is no matching structural object id' do
    expect do
      batch_process.file = preservica_parent_no_structural
      batch_process.save
      expect(batch_process.batch_ingest_events.count).to eq(1)
      expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] Unable to log in to Preservica for /preservica/api/entity/structural-objects/7fe35e8c-c21a-444a-a2e2-e3c926b519d6.")
    end.to change { ChildObject.count }.by(0)
  end

  # rubocop:disable Metrics/LineLength
  it 'can send an error when there is no matching information object id with pattern 1' do
    expect do
      batch_process.file = preservica_parent_no_information_pattern_1
      batch_process.save
      expect(batch_process.batch_ingest_events.count).to eq(1)
      expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] Failed to open TCP connection to testpreservica:443 (Connection refused - connect(2) for \"testpreservica\" port 443) for /preservica/api/entity/structural-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e4b.").or eq("Skipping row [2] execution expired for /preservica/api/entity/structural-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e4b.").or eq("Skipping row [2] Failed to open TCP connection to testpreservica:443 (getaddrinfo: Name or service not known) for /preservica/api/entity/structural-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e4b.")
    end.to change { ChildObject.count }.by(0)
  end

  it 'can send an error when there is no matching information object id with pattern 2' do
    expect do
      batch_process.file = preservica_parent_no_information_pattern_2
      batch_process.save
      expect(batch_process.batch_ingest_events.count).to eq(1)
      expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] execution expired for /preservica/api/entity/information-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e5c.").or eq("Skipping row [2] Failed to open TCP connection to testpreservica:443 (getaddrinfo: Temporary failure in name resolution) for /preservica/api/entity/information-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e5c.").or eq("Skipping row [2] Failed to open TCP connection to testpreservica:443 (Connection refused - connect(2) for \"testpreservica\" port 443) for /preservica/api/entity/information-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e5c.").or eq("Skipping row [2] Failed to open TCP connection to testpreservica:443 (getaddrinfo: Name or service not known) for /preservica/api/entity/information-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e5c.")
    end.to change { ChildObject.count }.by(0)
  end

  it 'can send an error when there is no matching representation with pattern 1' do
    expect do
      batch_process.file = preservica_parent_no_representation_pattern_1
      batch_process.save
      expect(batch_process.batch_ingest_events.count).to eq(1)
      # TODO: fix double for
      expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] No matching representation found in Preservica for /preservica/api/entity/structural-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e3a for /preservica/api/entity/structural-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e3a.")
    end.to change { ChildObject.count }.by(0)
  end

  it 'can send an error when there is no matching representation with pattern 2' do
    expect do
      batch_process.file = preservica_parent_no_representation_pattern_2
      batch_process.save
      expect(batch_process.batch_ingest_events.count).to eq(1)
      # TODO: fix double for
      expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] No matching representation found in Preservica for /preservica/api/entity/information-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e7e for /preservica/api/entity/information-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e7e.")
    end.to change { ChildObject.count }.by(0)
  end

  it 'can send an error when there is no active generations with pattern 1' do
    expect do
      batch_process.file = preservica_parent_no_generation_pattern_1
      batch_process.save
      expect(batch_process.batch_ingest_events.count).to eq(1)
      # TODO: Fix double id
      expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] No active generations found in Preservica for ae328d84-e429-4d46-a865-9ee11157b900 for /preservica/api/entity/structural-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a5e9z.")
    end.to change { ChildObject.count }.by(0)
  end

  it 'can send an error when there is no active generations with pattern 2' do
    expect do
      batch_process.file = preservica_parent_no_generation_pattern_2
      batch_process.save
      expect(batch_process.batch_ingest_events.count).to eq(1)
      # TODO: fix double id
      expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] No active generations found in Preservica for ae328d84-e429-4d46-a865-9ee11157b900 for /preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e5z.")
    end.to change { ChildObject.count }.by(0)
  end

  it 'can send an error when there is a checksum mismatch with pattern 1' do
    expect do
      batch_process.file = preservica_parent_checksum_mismatch_pattern_1
      batch_process.save
      po = ParentObject.find(200_000_000)
      expect(po.events_for_batch_process(batch_process).count).to be > 1
      expect(po.events_for_batch_process(batch_process)[1].reason).to eq("execution expired").or eq("Failed to open TCP connection to testpreservica:443 (Connection refused - connect(2) for \"testpreservica\" port 443)").or eq("Failed to open TCP connection to testpreservica:443 (getaddrinfo: Name or service not known)")
    end.to change { ChildObject.count }.by(0)
  end

  it 'can send an error when there is a checksum mismatch with pattern 2' do
    expect do
      batch_process.file = preservica_parent_checksum_mismatch_pattern_2
      batch_process.save
      po = ParentObject.find(200_000_000)
      expect(po.events_for_batch_process(batch_process).count).to be > 1
      expect(po.events_for_batch_process(batch_process)[1].reason).to eq("execution expired").or eq("Failed to open TCP connection to testpreservica:443 (Connection refused - connect(2) for \"testpreservica\" port 443)").or eq("Failed to open TCP connection to testpreservica:443 (getaddrinfo: Name or service not known)")
    end.to change { ChildObject.count }.by(0)
  end

  it 'can send an error when there is no sha512 found with pattern 1' do
    expect do
      batch_process.file = preservica_parent_no_sha_pattern_1
      batch_process.save
      expect(batch_process.batch_ingest_events.count).to eq(1)
      expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] SHA mismatch found in Preservica for 1.").or eq("Skipping row [2] Unable to log in to Preservica for /preservica/api/entity/structural-objects/2e42a2bb-8953-41b6-bcc3-1a19c86a7u8y.")
    end.to change { ChildObject.count }.by(0)
  end

  it 'can send an error when there is no sha512 found with pattern 2' do
    expect do
      batch_process.file = preservica_parent_no_sha_pattern_2
      batch_process.save
      expect(batch_process.batch_ingest_events.count).to eq(1)
      expect(batch_process.batch_ingest_events[0].reason).to eq("Skipping row [2] SHA mismatch found in Preservica for 1 for /preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a8y7u.")
    end.to change { ChildObject.count }.by(0)
  end
  # rubocop:enable Metrics/LineLength
end

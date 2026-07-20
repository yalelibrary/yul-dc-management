# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Preservica::PreservicaObject, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  subject(:batch_process) { BatchProcess.new }
  let(:admin_set) { AdminSet.find_by(key: 'sml') }
  let(:user) { FactoryBot.create(:user, uid: "mk2529") }
  let(:preservica_ingest_case_one) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_paths[0], "csv", "preservica", "preservica_ingest_case_one.csv")) }
  let(:expected_captions) do
    ["ms_0664_s02_b016_f0268_0001.tif",
     "ms_0664_s02_b016_f0268_0002.tif",
     "ms_0664_s02_b016_f0268_0003.tif",
     "ms_0664_s02_b016_f0269_0001.tif",
     "ms_0664_s02_b016_f0269_0002.tif"]
  end
  let(:expected_content_object_uris) do
    %w[cccc0002-0000-4000-8000-000000000002
       cccc0001-0000-4000-8000-000000000001
       cccc0003-0000-4000-8000-000000000003
       cccc0005-0000-4000-8000-000000000005
       cccc0004-0000-4000-8000-000000000004].map do |ref|
      "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/#{ref}"
    end
  end

  around do |example|
    preservica_host = ENV['PRESERVICA_HOST']
    preservica_creds = ENV['PRESERVICA_CREDENTIALS']
    ENV['PRESERVICA_HOST'] = "testpreservica"
    ENV['PRESERVICA_CREDENTIALS'] = '{"sml": {"username":"xxxxx", "password":"xxxxx"}}'
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
    user.add_role(:editor, admin_set)
    login_as(:user)
    batch_process.user_id = user.id
    stub_pdfs
    stub_preservica_aspace_single
    stub_preservica_login
    fixtures = %w[preservica/api/entity/structural-objects/eeee0001-0000-4000-8000-000000000001/children
                  preservica/api/entity/structural-objects/88e52625-0000-4000-8000-00000000bad1/children
                  preservica/api/entity/information-objects/aaaa0001-0000-4000-8000-000000000001/representations
                  preservica/api/entity/information-objects/aaaa0001-0000-4000-8000-000000000001/representations/Preservation
                  preservica/api/entity/information-objects/aaaa0002-0000-4000-8000-000000000002/representations
                  preservica/api/entity/information-objects/aaaa0002-0000-4000-8000-000000000002/representations/Preservation
                  preservica/api/entity/content-objects/cccc0001-0000-4000-8000-000000000001/generations
                  preservica/api/entity/content-objects/cccc0001-0000-4000-8000-000000000001/generations/1
                  preservica/api/entity/content-objects/cccc0001-0000-4000-8000-000000000001/generations/1/bitstreams/1
                  preservica/api/entity/content-objects/cccc0002-0000-4000-8000-000000000002/generations
                  preservica/api/entity/content-objects/cccc0002-0000-4000-8000-000000000002/generations/1
                  preservica/api/entity/content-objects/cccc0002-0000-4000-8000-000000000002/generations/1/bitstreams/1
                  preservica/api/entity/content-objects/cccc0003-0000-4000-8000-000000000003/generations
                  preservica/api/entity/content-objects/cccc0003-0000-4000-8000-000000000003/generations/1
                  preservica/api/entity/content-objects/cccc0003-0000-4000-8000-000000000003/generations/1/bitstreams/1
                  preservica/api/entity/content-objects/cccc0004-0000-4000-8000-000000000004/generations
                  preservica/api/entity/content-objects/cccc0004-0000-4000-8000-000000000004/generations/1
                  preservica/api/entity/content-objects/cccc0004-0000-4000-8000-000000000004/generations/1/bitstreams/1
                  preservica/api/entity/content-objects/cccc0005-0000-4000-8000-000000000005/generations
                  preservica/api/entity/content-objects/cccc0005-0000-4000-8000-000000000005/generations/1
                  preservica/api/entity/content-objects/cccc0005-0000-4000-8000-000000000005/generations/1/bitstreams/1
                  preservica/api/entity/content-objects/dddd0001-0000-4000-8000-000000000001/generations
                  preservica/api/entity/content-objects/dddd0001-0000-4000-8000-000000000001/generations/1]

    fixtures.each do |fixture|
      stub_request(:get, "https://test#{fixture}").to_return(
        status: 200, body: File.open(File.join(fixture_paths[0], "#{fixture}.xml"))
      )
    end

    { "cccc0001-0000-4000-8000-000000000001" => "ae328d84-e429-4d46-a865-9ee11157b486",
      "cccc0002-0000-4000-8000-000000000002" => "ae328d84-e429-4d46-a865-9ee11157b486",
      "cccc0003-0000-4000-8000-000000000003" => "ae328d84-e429-4d46-a865-9ee11157b486",
      "cccc0004-0000-4000-8000-000000000004" => "ae328d84-e429-4d46-a865-9ee11157b487",
      "cccc0005-0000-4000-8000-000000000005" => "ae328d84-e429-4d46-a865-9ee11157b487" }.each do |content_object, tif_source|
      stub_request(:get, "https://testpreservica/api/entity/content-objects/#{content_object}/generations/1/bitstreams/1/content").to_return(
        status: 200, body: File.open(File.join(fixture_paths[0], "preservica/api/entity/content-objects/#{tif_source}/generations/1/bitstreams/1/content.tif"), 'rb')
      )
    end
  end

  def access_primary_path(oid)
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    File.join(ENV['ACCESS_PRIMARY_MOUNT'], format("%02d", pairtree_path.first), pairtree_path, "#{oid}.tif")
  end

  it 'builds an ordered, pdf-free image list from a multi-folder structural object' do
    image_service = PreservicaImageService.new("/structural-objects/eeee0001-0000-4000-8000-000000000001", "sml")
    image_list = image_service.image_list("Preservation")
    expect(image_list.count).to eq 5
    expect(image_list.map { |image| image[:caption] }).to eq expected_captions
    expect(image_list.map { |image| image[:preservica_content_object_uri] }).to eq expected_content_object_uris
  end

  it 'raises a clear error when the structural object contains nested folders' do
    image_service = PreservicaImageService.new("/structural-objects/88e52625-0000-4000-8000-00000000bad1", "sml")
    expect do
      image_service.image_list("Preservation")
    end.to raise_error(PreservicaImageService::PreservicaImageServiceError, /not information objects/)
  end

  it 'creates a single parent with ordered children from every information object' do
    expected_oids = (200_000_001..200_000_005).to_a
    expected_oids.each do |oid|
      File.delete(access_primary_path(oid)) if File.exist?(access_primary_path(oid))
    end
    allow(S3Service).to receive(:s3_exists?).and_return(false)

    expect do
      batch_process.file = preservica_ingest_case_one
      batch_process.save
    end.to change { ChildObject.count }.by(5)

    parent_object = ParentObject.find(200_000_000)
    child_objects = parent_object.child_objects.order(:order)
    expect(child_objects.map(&:caption)).to eq expected_captions
    expect(child_objects.map(&:order)).to eq [1, 2, 3, 4, 5]
    expect(child_objects.map(&:preservica_content_object_uri)).to eq expected_content_object_uris
    expect(child_objects.map(&:caption)).to all(end_with(".tif"))
    expect(parent_object.child_object_count).to eq 5
    expect(parent_object.last_preservica_update).not_to eq nil
    expect(child_objects.first.sha512_checksum).to eq "1932c08c4670d5010fac6fa363ad5d9be7a4e7d743757ba5eefbbe8e3f9b2fb89b1604c1e527cfae6f47a91a60845268e91d2723aa63a90dd4735f75017569f7"
    expected_oids.each do |oid|
      expect(File.exist?(access_primary_path(oid))).to eq true
    end
  ensure
    expected_oids&.each do |oid|
      File.delete(access_primary_path(oid)) if File.exist?(access_primary_path(oid))
    end
  end
end

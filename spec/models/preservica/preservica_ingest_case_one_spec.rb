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
                  preservica/api/entity/structural-objects/eeee0002-0000-4000-8000-000000000002/children
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
                  preservica/api/entity/content-objects/dddd0001-0000-4000-8000-000000000001/generations/1
                  preservica/api/entity/information-objects/aaaa0003-0000-4000-8000-000000000003/representations
                  preservica/api/entity/information-objects/aaaa0003-0000-4000-8000-000000000003/representations/Preservation
                  preservica/api/entity/content-objects/cccc0006-0000-4000-8000-000000000006/generations
                  preservica/api/entity/content-objects/cccc0006-0000-4000-8000-000000000006/generations/1
                  preservica/api/entity/content-objects/cccc0006-0000-4000-8000-000000000006/generations/1/bitstreams/1
                  preservica/api/entity/content-objects/cccc0007-0000-4000-8000-000000000007/generations
                  preservica/api/entity/content-objects/cccc0007-0000-4000-8000-000000000007/generations/1
                  preservica/api/entity/content-objects/cccc0007-0000-4000-8000-000000000007/generations/1/bitstreams/1]

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

  it 'orders folders and their files without giving weight to case' do
    image_service = PreservicaImageService.new("/structural-objects/eeee0002-0000-4000-8000-000000000002", "sml")
    image_list = image_service.image_list("Preservation")
    expect(image_list.map { |image| image[:preservica_folder_label] }).to eq(
      (["[Preservica] ms_0664_s02-m-b016_f0268"] * 3) +
      (["[Preservica] ms_0664_s02-M-b016_f0269"] * 2) +
      (["[Preservica] ms_0664_s02-m-b016_f0270"] * 2)
    )
    expect(image_list.map { |image| image[:caption] }).to eq expected_captions + ["ms_0664_s02_b016_f0270_a001.tif", "ms_0664_s02_b016_f0270_A002.tif"]
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
    # when import pattern one, with a folder architecture, the v3 structures should contain one top-level Range per
    # folder (information object) directly (no wrapper range, matching the structure-editor format), labeled with the
    # folder title, whose items are the Canvases for the child objects in that folder.
    # This fixture has two information objects (f0268 with three images, f0269 with two), so there are two ranges.
    iiif_manifest = parent_object.iiif_manifest
    ranges = iiif_manifest['structures']

    expect(ranges.count).to eq 2
    expect(ranges.map { |range| range['type'] }).to all(eq("Range"))

    # ranges are ordered by folder index and labeled with the information object title
    # range ids are the bare information-object UUID, matching the structure editor (no /range/ URI wrapper)
    expect(ranges.first['label']).to eq({ "en" => ["[Preservica] ms_0664_s02_b016_f0268"] })
    expect(ranges.first['id']).to eq "aaaa0001-0000-4000-8000-000000000001"
    expect(ranges.second['label']).to eq({ "en" => ["[Preservica] ms_0664_s02_b016_f0269"] })
    expect(ranges.second['id']).to eq "aaaa0002-0000-4000-8000-000000000002"

    # each Range's items are the Canvases for the child objects in that folder, ordered the same way they appear in the
    # Preservica folder (preservica_content_object_index), which is independent of the caption-based page ordering. The
    # oids therefore are not sequential: the page order is caption-sorted while the range preserves the Preservica order.
    base_url = IiifRangeBuilder.manifest_base_url
    first_folder_canvases = ranges.first['items']
    expect(first_folder_canvases.map { |canvas| canvas['type'] }).to all(eq("Canvas"))
    expect(first_folder_canvases.map { |canvas| canvas['id'] }).to eq [
      "#{base_url}/oid/200000000/canvas/200000002",
      "#{base_url}/oid/200000000/canvas/200000001",
      "#{base_url}/oid/200000000/canvas/200000003"
    ]

    second_folder_canvases = ranges.second['items']
    expect(second_folder_canvases.map { |canvas| canvas['type'] }).to all(eq("Canvas"))
    expect(second_folder_canvases.map { |canvas| canvas['id'] }).to eq [
      "#{base_url}/oid/200000000/canvas/200000005",
      "#{base_url}/oid/200000000/canvas/200000004"
    ]

    # Universal Viewer resolves a Range's items by matching ids against the Canvases in the manifest, so every canvas
    # id referenced from `structures` must appear verbatim in `items`. A mismatch (e.g. a hardcoded base url that
    # disagrees with IIIF_MANIFESTS_BASE_URL) renders a structure that looks correct but cannot be navigated.
    manifest_canvas_ids = iiif_manifest['items'].map { |canvas| canvas['id'] }
    structure_canvas_ids = (first_folder_canvases + second_folder_canvases).map { |canvas| canvas['id'] }
    expect(manifest_canvas_ids).to include(*structure_canvas_ids)
  ensure
    expected_oids&.each do |oid|
      File.delete(access_primary_path(oid)) if File.exist?(access_primary_path(oid))
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Preservica::PreservicaObject, type: :model do
  around do |example|
    preservica_host = ENV['PRESERVICA_HOST']
    preservica_creds = ENV['PRESERVICA_CREDENTIALS']
    ENV['PRESERVICA_HOST'] = "testpreservica"
    ENV['PRESERVICA_CREDENTIALS'] = '{"brbl": {"username":"xxxxx", "password":"xxxxx"}}'
    perform_enqueued_jobs do
      example.run
    end
    ENV['PRESERVICA_HOST'] = preservica_host
    ENV['PRESERVICA_CREDENTIALS'] = preservica_creds
  end

  before do
    stub_preservica_login
    fixtures = %w[preservica/api/entity/structural-objects/7fe35e8c-c21a-444a-a2e2-e3c926b519c4/children
                  preservica/api/entity/information-objects/b31ba07e-88ce-4558-8e89-81cff9630699/representations
                  preservica/api/entity/information-objects/b31ba07e-88ce-4558-8e89-81cff9630699/representations/Access
                  preservica/api/entity/information-objects/b31ba07e-88ce-4558-8e89-81cff9630699/representations/Preservation
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations/2
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations/3
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations/1/bitstreams/1]

    fixtures.each do |fixture|
      stub_request(:get, "https://test#{fixture}").to_return(
        status: 200, body: File.open(File.join(fixture_path, "#{fixture}.xml"))
      )
    end
  end

  after do
    File.delete("tmp/testdownload.file") if File.exist?("tmp/testdownload.file")
  end

  it 'traverses hierarcy' do
    structured_object = Preservica::StructuralObject.where(admin_set_key: 'brbl', id: "7fe35e8c-c21a-444a-a2e2-e3c926b519c4")
    information_objects = structured_object.information_objects
    representations = information_objects[0].representations
    expect(representations[0].type).to eq("Access")
    content_objects = representations[0].content_objects
    generations = content_objects[0].active_generations
    bitstreams = generations[0].bitstreams
    formats = generations[0].formats

    checksum = bitstreams[0].sha512_checksum
    size = bitstreams[0].size
    expect(checksum).to eq("329f67d6c5cd707e6b7af8dd129e872369351faad8b63b2c80518cc54b386d7ec646e85873d28e6f904e44d9824506d1e055f2f716f0101afb948925e9713cc8")
    expect(size).to eq(2_274_948)
    expect(formats).to include("Tagged Image File Format")
  end

  context "with the file matching size and checksum" do
    before do
      stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations/1/bitstreams/1/content").to_return(
        status: 200, body: File.open(File.join(fixture_path, "preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations/1/bitstreams/1/content"), 'rb')
      )
    end
    it 'downloads bits to file' do
      structured_object = Preservica::StructuralObject.where(admin_set_key: 'brbl', id: "7fe35e8c-c21a-444a-a2e2-e3c926b519c4")
      information_objects = structured_object.information_objects
      representations = information_objects[0].representations
      content_objects = representations[0].content_objects
      generations = content_objects[0].active_generations
      bitstreams = generations[0].bitstreams
      bitstreams[0].download_to_file "tmp/testdownload.file"
      expect(File.size("tmp/testdownload.file")).to eq(bitstreams[0].size)
      expect(Digest::SHA512.file("tmp/testdownload.file").hexdigest).to eq(bitstreams[0].sha512_checksum)
    end
  end
  # rubocop disable:Layout/LineLength
  context 'with wrong file' do
    it 'throws exception with file mismatch' do
      stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations/1/bitstreams/1/content").to_return(
        status: 200, body: "Not the right data"
      )
      structured_object = Preservica::StructuralObject.where(admin_set_key: 'brbl', id: "7fe35e8c-c21a-444a-a2e2-e3c926b519c4")
      information_objects = structured_object.information_objects
      representations = information_objects[0].representations
      content_objects = representations[0].content_objects
      generations = content_objects[0].active_generations
      bitstreams = generations[0].bitstreams
      expect do
        bitstreams[0].download_to_file "tmp/testdownload.file"
      end .to raise_error(/The checksum for this object is different than the checksum that DCS expected. Please ensure your image folder in Preservica has SHA-512 fixity checksums./)
    end
    # rubocop enable:Layout/LineLength
    it 'does not throw an exception when the cases do not match' do
      stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations/1/bitstreams/1/content").to_return(
        status: 200, body: File.open(File.join(fixture_path, "preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations/1/bitstreams/2/content"), 'rb')
      )
      structured_object = Preservica::StructuralObject.where(admin_set_key: 'brbl', id: "7fe35e8c-c21a-444a-a2e2-e3c926b519c4")
      information_objects = structured_object.information_objects
      representations = information_objects[0].representations
      content_objects = representations[0].content_objects
      generations = content_objects[0].active_generations
      bitstreams = generations[0].bitstreams
      expect { bitstreams[0].download_to_file "tmp/testdownload.file" }.not_to raise_error(/Checksum mismatch/)
    end
  end

  it 'refreshes credentials' do
    structured_object = Preservica::StructuralObject.where(admin_set_key: 'brbl', id: "7fe35e8c-c21a-444a-a2e2-e3c926b519c4")
    structured_object.preservica_client.refresh
  end

  it 'loads information objects by id' do
    information_object = Preservica::InformationObject.where(admin_set_key: 'brbl', id: "test id")
    expect(information_object).not_to be_nil
    expect(information_object.id).to eq("test id")
  end

  it 'loads content objects by id' do
    content_object = Preservica::ContentObject.where(admin_set_key: 'brbl', id: "test id")
    expect(content_object).not_to be_nil
    expect(content_object.id).to eq("test id")
  end

  it 'loads representation by information object id and type' do
    representation = Preservica::Representation.where(admin_set_key: 'brbl', type: "test type", information_object_id: "info id")
    expect(representation).not_to be_nil
    expect(representation.type).to eq("test type")
  end

  it 'retrieves generations format group' do
    structured_object = Preservica::StructuralObject.where(admin_set_key: 'brbl', id: "7fe35e8c-c21a-444a-a2e2-e3c926b519c4")
    expect(structured_object).not_to be_nil
    information_objects = structured_object.information_objects
    representations = information_objects[0].representations
    content_objects = representations[0].content_objects
    generations = content_objects[0].active_generations
    format_group = generations[0].format_group
    expect(format_group.first).to eq("pdf")
  end

  it 'retrieves representations based on type' do
    structured_object = Preservica::StructuralObject.where(admin_set_key: 'brbl', id: "7fe35e8c-c21a-444a-a2e2-e3c926b519c4")
    information_objects = structured_object.information_objects
    access_representations = information_objects[0].access_representations
    expect(access_representations[0].type).to eq "Access"
    preservation_representations = information_objects[0].preservation_representations
    expect(preservation_representations[0].type).to eq "Preservation"
  end

  it 'retrieves correct representations with fetch' do
    structured_object = Preservica::StructuralObject.where(admin_set_key: 'brbl', id: "7fe35e8c-c21a-444a-a2e2-e3c926b519c4")
    information_objects = structured_object.information_objects
    expect(information_objects[0].fetch_by_representation_type('Access')[0].type).to eq("Access")
    expect(information_objects[0].fetch_by_representation_type('Preservation')[0].type).to eq("Preservation")
  end

  it 'retrieves generation based on active true' do
    structured_object = Preservica::StructuralObject.where(admin_set_key: 'brbl', id: "7fe35e8c-c21a-444a-a2e2-e3c926b519c4")
    information_objects = structured_object.information_objects
    representations = information_objects[0].representations
    expect(representations[0].type).to eq("Access")
    content_objects = representations[0].content_objects
    generations = content_objects[0].active_generations
    # in fixtures 1 false 2 true
    expect(generations.count).to eq 2
  end

  context 'with paginated information objects' do
    before do
      stub_request(:get, "https://testpreservica/api/entity/structural-objects/35713feb-6845-437f-a269-5f2ac09c7e46/children").to_return(
        status: 200, body: File.open(File.join(fixture_path, "preservica/api/entity/structural-objects/35713feb-6845-437f-a269-5f2ac09c7e46/children.xml"))
      )
      stub_request(:get, "https://testpreservica/api/entity/structural-objects/35713feb-6845-437f-a269-5f2ac09c7e46/children?start=100").to_return(
        status: 200, body: File.open(File.join(fixture_path, "preservica/api/entity/structural-objects/35713feb-6845-437f-a269-5f2ac09c7e46/children_page_2.xml"))
      )
    end

    it 'retrieves all paginated information objects' do
      structured_object = Preservica::StructuralObject.where(admin_set_key: 'brbl', id: "35713feb-6845-437f-a269-5f2ac09c7e46")
      expect(structured_object.information_objects.count).to be(134)
    end
  end
end

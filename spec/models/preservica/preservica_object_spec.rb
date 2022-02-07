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
    stub_request(:post, "https://testpreservica/api/accesstoken/login").to_return(status: 200, body: '{"token":"test"}')
    stub_request(:post, "https://testpreservica/api/accesstoken/refresh").to_return(status: 200, body: '{"token":"test"}')
    fixtures = %w[preservica/api/entity/structural-objects/7fe35e8c-c21a-444a-a2e2-e3c926b519c4/children
                  preservica/api/entity/information-objects/b31ba07e-88ce-4558-8e89-81cff9630699/representations
                  preservica/api/entity/information-objects/b31ba07e-88ce-4558-8e89-81cff9630699/representations/Access-2
                  preservica/api/entity/information-objects/b31ba07e-88ce-4558-8e89-81cff9630699/representations/Preservation-1
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
    expect(formats).to include("Acrobat PDF 1.7 - Portable Document Format")
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
      File.delete("tmp/testdownload.file")
    end
  end

  context 'with wrong file' do
    before do
      stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations/1/bitstreams/1/content").to_return(
        status: 200, body: "Not the right data"
      )
    end
    it 'throws exception with file mismatch' do
      structured_object = Preservica::StructuralObject.where(admin_set_key: 'brbl', id: "7fe35e8c-c21a-444a-a2e2-e3c926b519c4")
      information_objects = structured_object.information_objects
      representations = information_objects[0].representations
      content_objects = representations[0].content_objects
      generations = content_objects[0].active_generations
      bitstreams = generations[0].bitstreams
      expect { bitstreams[0].download_to_file "tmp/testdownload.file" }.to raise_error
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

  it 'loads representation by information object id and name' do
    representation = Preservica::Representation.where(admin_set_key: 'brbl', name: "test name", information_object_id: "info id")
    expect(representation).not_to be_nil
    expect(representation.name).to eq("test name")
  end

  it 'retrieves representations based on type' do
    structured_object = Preservica::StructuralObject.where(admin_set_key: 'brbl', id: "7fe35e8c-c21a-444a-a2e2-e3c926b519c4")
    information_objects = structured_object.information_objects
    access_representations = information_objects[0].access_representations
    expect(access_representations[0].type).to eq "Access"
    preservation_representations = information_objects[0].preservation_representations
    expect(preservation_representations[0].type).to eq "Preservation"
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
end

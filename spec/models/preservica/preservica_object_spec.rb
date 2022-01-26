# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PreservicaObject, type: :model do
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
    fixtures = %w[preservica/api/entity/structural-objects/7fe35e8c-c21a-444a-a2e2-e3c926b519c4/children
                  preservica/api/entity/information-objects/b31ba07e-88ce-4558-8e89-81cff9630699/representations
                  preservica/api/entity/information-objects/b31ba07e-88ce-4558-8e89-81cff9630699/representations/Access-2
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations/1/bitstreams/1]

    fixtures.each do |fixture|
      stub_request(:get, "https://test#{fixture}").to_return(
        status: 200, body: File.open(File.join(fixture_path, "#{fixture}.xml"))
      )
    end
    stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations/1/bitstreams/1/content").to_return(
      status: 200, body: File.open(File.join(fixture_path, "preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations/1/bitstreams/1/content"))
    )
  end

  it 'traverses hierarcy' do
    structured_object = StructuralObject.where(admin_set_key: 'brbl', id: "7fe35e8c-c21a-444a-a2e2-e3c926b519c4")
    information_objects = structured_object.information_objects
    representations = information_objects[0].representations
    content_objects = representations[0].content_objects
    generations = content_objects[0].active_generations
    bitstreams = generations[0].bitstreams

    checksum = bitstreams[0].sha512_checksum
    size = bitstreams[0].size
    expect(checksum).to eq("03de43264ec0acf6b9c2599379b7c6035defcf7ac36ec727fd42bde9d27ad351edd3e5131742475e9b01bab683e62bb1a746dc6fd8504120484e13ed2f30d8f8")
    expect(size).to eq(14_327_985)

    expect(bitstreams[0].bits).to eq("IMAGE CONTENT")
  end
end

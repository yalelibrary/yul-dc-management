# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Preservica::PreservicaObject, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  subject(:batch_process) { BatchProcess.new }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl') }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:preservica_parent) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica_parent.csv")) }
  let(:preservica_parent_with_children) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica_parent_with_children.csv")) }

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
    user.add_role(:editor, admin_set)
    login_as(:user)
    batch_process.user_id = user.id
    stub_metadata_cloud("AS-200000000", "aspace")
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
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations/1/bitstreams/1
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

    fixtures.each do |fixture|
      stub_request(:get, "https://test#{fixture}").to_return(
        status: 200, body: File.open(File.join(fixture_path, "#{fixture}.xml"))
      )
    end
  end

  # check : create a parent via csv batch process
  # check : create child objects
  # check : An OID is generated
  # check : A DCS child object is created
  # check : The order is set based on the order in the Preservica object
  # check : The preservica_*_uri fields are populated
  # Identify the representation that corresponds to the preservica_representation_name field of the parent.
  # Identify the active generation is a TIFF, or else throw an error
  # check : The Bitstream's SHA512 checksum is stored in the sha512_checksum field
  # The TIFF Bitstream's Content is downloaded to the pairtree
  # Subsequent PTIFF creation job is run

  # Add method to update last_preservica_update

  it 'can create parent object via batch process' do
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(SetupMetadataJob).to receive(:perform).and_return(true)
    # rubocop:enable RSpec/AnyInstance
    expect do
      batch_process.file = preservica_parent
      batch_process.save
    end.to change { ParentObject.count }.from(0).to(1)
  end

  it 'can create child objects' do
    expect do
      batch_process.file = preservica_parent_with_children
      batch_process.save
    end.to change { ChildObject.count }.from(0).to(3)
    co_first = ChildObject.first
    expect(co_first.oid).to be 200_000_004
    expect(co_first.parent_object_oid).to be 200_000_000
    expect(co_first.order).to be 1
    co_last = ChildObject.last
    expect(co_last.order).to be 3

    expect(co_first.preservica_content_object_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488"
    expect(co_first.preservica_generation_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations/1"
    expect(co_first.preservica_bitstream_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b488/generations/1/bitstreams/1"

    expect(co_first.sha512_checksum).to eq "329f67d6c5cd707e6b7af8dd129e872369351faad8b63b2c80518cc54b386d7ec646e85873d28e6f904e44d9824506d1e055f2f716f0101afb948925e9713cc8"
  end
end

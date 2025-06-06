# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Preservica::PreservicaObject, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  subject(:batch_process) { BatchProcess.new }
  let(:admin_set) { AdminSet.find_by(key: 'sml') }
  let(:user) { FactoryBot.create(:user, uid: "mk2529") }
  let(:permission_set) { FactoryBot.create(:permission_set, key: 'psKey') }
  let(:preservica_owp_parent_with_children) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_owp_parent_with_permission_set.csv")) }

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
    user.add_role(:administrator, permission_set)
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
        status: 200, body: File.open(File.join(fixture_path, "#{fixture}.xml"))
      )
    end
    stub_preservica_tifs_set_of_three
  end

  it 'can create child objects' do
    File.delete("spec/fixtures/images/access_primaries/00/01/20/00/00/00/200000001.tif") if File.exist?("spec/fixtures/images/access_primaries/00/01/20/00/00/00/200000001.tif")
    File.delete("spec/fixtures/images/access_primaries/00/02/20/00/00/00/200000002.tif") if File.exist?("spec/fixtures/images/access_primaries/00/02/20/00/00/00/200000002.tif")
    File.delete("spec/fixtures/images/access_primaries/00/03/20/00/00/00/200000003.tif") if File.exist?("spec/fixtures/images/access_primaries/00/03/20/00/00/00/200000003.tif")

    allow(S3Service).to receive(:s3_exists?).and_return(false)
    expect(File.exist?("spec/fixtures/images/access_primaries/00/01/20/00/00/00/200000001.tif")).to eq false
    expect(File.exist?("spec/fixtures/images/access_primaries/00/02/20/00/00/00/200000002.tif")).to eq false
    expect(File.exist?("spec/fixtures/images/access_primaries/00/03/20/00/00/00/200000003.tif")).to eq false
    expect do
      batch_process.file = preservica_owp_parent_with_children
      batch_process.save
    end.to change { ChildObject.count }.from(0).to(3)
    po_first = ParentObject.first
    co_first = ChildObject.first
    expect(co_first.oid).to eq 200_000_001
    expect(co_first.parent_object_oid).to eq 200_000_000
    expect(co_first.order).to eq 1
    co_last = ChildObject.last
    expect(co_last.order).to eq 3
    expect(po_first.last_preservica_update).not_to eq nil
    expect(po_first.visibility).to eq "Open with Permission"
    expect(co_first.preservica_content_object_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486"
    expect(co_first.preservica_generation_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1"
    expect(co_first.preservica_bitstream_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1/bitstreams/1"
    expect(co_first.sha512_checksum).to eq "1932c08c4670d5010fac6fa363ad5d9be7a4e7d743757ba5eefbbe8e3f9b2fb89b1604c1e527cfae6f47a91a60845268e91d2723aa63a90dd4735f75017569f7"
    expect(co_first.caption).to eq "mss_29_s03_b092_f0019.TIF"
    expect(File.exist?("spec/fixtures/images/access_primaries/00/01/20/00/00/00/200000001.tif")).to eq true
    expect(File.exist?("spec/fixtures/images/access_primaries/00/02/20/00/00/00/200000002.tif")).to eq true
    expect(File.exist?("spec/fixtures/images/access_primaries/00/03/20/00/00/00/200000003.tif")).to eq true
    expect(co_first.ptiff_conversion_at.present?).to be_truthy
    File.delete("spec/fixtures/images/access_primaries/00/01/20/00/00/00/200000001.tif") if File.exist?("spec/fixtures/images/access_primaries/00/01/20/00/00/00/200000001.tif")
    File.delete("spec/fixtures/images/access_primaries/00/02/20/00/00/00/200000002.tif") if File.exist?("spec/fixtures/images/access_primaries/00/02/20/00/00/00/200000002.tif")
    File.delete("spec/fixtures/images/access_primaries/00/03/20/00/00/00/200000003.tif") if File.exist?("spec/fixtures/images/access_primaries/00/03/20/00/00/00/200000003.tif")
  end
end

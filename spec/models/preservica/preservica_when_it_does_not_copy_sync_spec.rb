# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Preservica::PreservicaObject, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  subject(:batch_process) { BatchProcess.new }
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl') }
  let(:admin_set_sml) { FactoryBot.create(:admin_set, key: 'sml') }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:preservica_parent_with_children) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_parent_with_children.csv")) }
  let(:preservica_sync) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "preservica", "preservica_sync.csv")) }
  let(:logger_mock) { instance_double('Rails.logger').as_null_object }

  around do |example|
    preservica_host = ENV['PRESERVICA_HOST']
    preservica_creds = ENV['PRESERVICA_CREDENTIALS']
    ENV['PRESERVICA_HOST'] = "testpreservica"
    ENV['PRESERVICA_CREDENTIALS'] = '{"brbl": {"username":"xxxxx", "password":"xxxxx"}}'
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
    allow(Rails.logger).to receive(:info) { :logger_mock }
    login_as(:user)
    batch_process.user_id = user.id
    stub_pdfs
    stub_preservica_aspace_single
    stub_preservica_login
    fixtures = %w[preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3r/representations
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
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1/bitstreams/1
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f45/representations
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f45/representations/Access
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f45/representations/Preservation
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b485/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b485/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b485/generations/1/bitstreams/1]

    changing_fixtures = %w[preservica/api/entity/structural-objects/7fe35e8c-c21a-444a-a2e2-e3c926b519c5/children]

    fixtures.each do |fixture|
      stub_request(:get, "https://test#{fixture}").to_return(
        status: 200, body: File.open(File.join(fixture_path, "#{fixture}.xml"))
      )
    end

    changing_fixtures.each do |fixture|
      stub_request(:get, "https://test#{fixture}").to_return(
        status: 200, body: File.open(File.join(fixture_path, "#{fixture}.xml"))
      ).times(2).then.to_return(
        status: 200, body: File.open(File.join(fixture_path, "#{fixture}_add_sync.xml"))
      )
    end

    stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b485/generations/1/bitstreams/1/content").to_return(
      status: 200, body: File.open(File.join(fixture_path, "preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b485/generations/1/bitstreams/1/content.tif"), 'rb')
    )
    stub_preservica_tifs_set_of_three
  end

  context 'user with permission' do
    before do
      user.add_role(:editor, admin_set)
      login_as(:user)
    end

    it 'can recognize when child image is not copied to the shares at yale by preservica' do
      File.delete("spec/fixtures/images/access_primaries/00/01/20/00/00/00/200000001.tif") if File.exist?("spec/fixtures/images/access_primaries/00/01/20/00/00/00/200000001.tif")
      File.delete("spec/fixtures/images/access_primaries/00/02/20/00/00/00/200000002.tif") if File.exist?("spec/fixtures/images/access_primaries/00/02/20/00/00/00/200000002.tif")
      File.delete("spec/fixtures/images/access_primaries/00/03/20/00/00/00/200000003.tif") if File.exist?("spec/fixtures/images/access_primaries/00/03/20/00/00/00/200000003.tif")
      File.delete("spec/fixtures/images/access_primaries/00/04/20/00/00/00/200000004.tif") if File.exist?("spec/fixtures/images/access_primaries/00/04/20/00/00/00/200000004.tif")
      File.delete("spec/fixtures/images/access_primaries/00/05/20/00/00/00/200000005.tif") if File.exist?("spec/fixtures/images/access_primaries/00/05/20/00/00/00/200000005.tif")
      File.delete("spec/fixtures/images/access_primaries/00/06/20/00/00/00/200000006.tif") if File.exist?("spec/fixtures/images/access_primaries/00/06/20/00/00/00/200000006.tif")
      File.delete("spec/fixtures/images/access_primaries/00/07/20/00/00/00/200000007.tif") if File.exist?("spec/fixtures/images/access_primaries/00/07/20/00/00/00/200000007.tif")

      allow(S3Service).to receive(:s3_exists?).and_return(false)
      expect(File.exist?("spec/fixtures/images/access_primaries/00/01/20/00/00/00/200000001.tif")).to eq false
      expect(File.exist?("spec/fixtures/images/access_primaries/00/02/20/00/00/00/200000002.tif")).to eq false
      expect(File.exist?("spec/fixtures/images/access_primaries/00/03/20/00/00/00/200000003.tif")).to eq false
      expect(File.exist?("spec/fixtures/images/access_primaries/00/04/20/00/00/00/200000004.tif")).to eq false
      expect(File.exist?("spec/fixtures/images/access_primaries/00/05/20/00/00/00/200000005.tif")).to eq false
      expect(File.exist?("spec/fixtures/images/access_primaries/00/06/20/00/00/00/200000006.tif")).to eq false
      expect(File.exist?("spec/fixtures/images/access_primaries/00/07/20/00/00/00/200000007.tif")).to eq false
      expect do
        batch_process.file = preservica_parent_with_children
        batch_process.save
      end.to change { ChildObject.count }.from(0).to(3)
      po_first = ParentObject.first
      co_first = po_first.child_objects.first
      expect(po_first.last_preservica_update).not_to eq nil
      expect(co_first.order).to eq 1
      expect(co_first.preservica_content_object_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486"

      expect(File.exist?("spec/fixtures/images/access_primaries/00/01/20/00/00/00/200000001.tif")).to eq true
      expect(File.exist?("spec/fixtures/images/access_primaries/00/02/20/00/00/00/200000002.tif")).to eq true
      expect(File.exist?("spec/fixtures/images/access_primaries/00/03/20/00/00/00/200000003.tif")).to eq true
      expect(co_first.ptiff_conversion_at.present?).to be_truthy
      expect(po_first.child_objects.count).to eq 3

      allow(co_first).to receive(:access_primary_exists?).and_return(false) # .times(2).then.and_return(true)
      allow(co_first.pyramidal_tiff).to receive(:valid?).and_return(false) # .times(2).then.and_return(true)
      sync_batch_process = BatchProcess.new(batch_action: 'resync with preservica', user: user)
      expect do
        sync_batch_process.file = preservica_sync
        sync_batch_process.save!
      end.to change { ChildObject.count }.from(3).to(4)
      # expect(Rails.logger).to have_received(:info).with("************ bitstream.rb # download_to_file +++ File.write wrote 310202 bites to file *************")

      expect(File.exist?("spec/fixtures/images/access_primaries/00/07/20/00/00/00/200000007.tif")).to eq true
      co_first = po_first.child_objects.first
      expect(co_first.order).to eq 1
      expect(co_first.preservica_content_object_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486"
      co_second = po_first.child_objects[1]
      expect(co_second.order).to eq 2
      expect(co_second.preservica_content_object_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489"
      co_third = po_first.child_objects[2]
      expect(co_third.order).to eq 3
      expect(co_third.preservica_content_object_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487"
      co_last = po_first.child_objects.last
      expect(co_last.order).to eq 4
      expect(co_last.preservica_content_object_uri).to eq "https://preservica-dev-v6.library.yale.edu/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b485"

      File.delete("spec/fixtures/images/access_primaries/00/01/20/00/00/00/200000001.tif") if File.exist?("spec/fixtures/images/access_primaries/00/01/20/00/00/00/200000001.tif")
      File.delete("spec/fixtures/images/access_primaries/00/02/20/00/00/00/200000002.tif") if File.exist?("spec/fixtures/images/access_primaries/00/02/20/00/00/00/200000002.tif")
      File.delete("spec/fixtures/images/access_primaries/00/03/20/00/00/00/200000003.tif") if File.exist?("spec/fixtures/images/access_primaries/00/03/20/00/00/00/200000003.tif")
      File.delete("spec/fixtures/images/access_primaries/00/04/20/00/00/00/200000004.tif") if File.exist?("spec/fixtures/images/access_primaries/00/04/20/00/00/00/200000004.tif")
      File.delete("spec/fixtures/images/access_primaries/00/05/20/00/00/00/200000005.tif") if File.exist?("spec/fixtures/images/access_primaries/00/05/20/00/00/00/200000005.tif")
      File.delete("spec/fixtures/images/access_primaries/00/06/20/00/00/00/200000006.tif") if File.exist?("spec/fixtures/images/access_primaries/00/06/20/00/00/00/200000006.tif")
      File.delete("spec/fixtures/images/access_primaries/00/07/20/00/00/00/200000007.tif") if File.exist?("spec/fixtures/images/access_primaries/00/07/20/00/00/00/200000007.tif")
    end
  end
end

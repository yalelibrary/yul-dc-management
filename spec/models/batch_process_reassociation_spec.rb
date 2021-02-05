# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true do
  subject(:batch_process) { described_class.new(batch_action: "reassociate child oids") }
  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:csv_upload) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "reassociation_example_small.csv")) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2002826") }
  let(:parent_object_old_one) { FactoryBot.create(:parent_object, oid: "2004548") }
  let(:parent_object_old_two) { FactoryBot.create(:parent_object, oid: "2004549") }

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  before do
    stub_metadata_cloud("2002826")
    stub_metadata_cloud("2004548")
    stub_metadata_cloud("2004549")
    stub_ptiffs_and_manifests
    parent_object
    parent_object_old_one
    parent_object_old_two
    login_as(:user)
    batch_process.user_id = user.id
    batch_process.file = csv_upload
    batch_process.save
  end

  # Original oids [2002826, 2004548, 2004548, 2004549, 2004549]

  it "can run a test" do
    co_one = ChildObject.find(1_011_398)
    co_three = ChildObject.find(1_021_926)
    po = ParentObject.find(2_002_826)
    po_old_one = ParentObject.find(2_004_548)
    po_old_two = ParentObject.find(2_004_549)
    expect(co_one.parent_object).to eq po
    expect(co_three.parent_object).to eq po
    expect(po.child_object_count).to eq 5
    expect(po_old_one.child_object_count).to eq 0
    expect(po_old_two.child_object_count).to eq 0
    expect(co_one.order).to eq 1
    expect(co_three.order).to eq 3
    expect(co_one.label).to eq "[Portrait of Grace Nail Johnson]"
    expect(co_three.label).to eq "Changed label, verso"
  end
end

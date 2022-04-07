# frozen_string_literal: true

require 'rails_helper'

# Putting this in a separate test file so expect / receive work correctly
RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true do
  subject(:batch_process) { described_class.new(batch_action: "reassociate child oids") }
  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:role) { FactoryBot.create(:role, name: editor) }
  let(:redirect) { Rack::Test::UploadedFile.new(Rails.root.join(fixture_path, "csv", "reassociation_example_redirect.csv")) }
  let(:parent_to_receive_children) { FactoryBot.create(:parent_object, oid: "2004550", admin_set_id: admin_set.id) }
  let(:parent_to_redirect) { FactoryBot.create(:parent_object, oid: "2004551", admin_set_id: admin_set.id, bib: "34567", call_number: "MSS MS 345") }
  let(:child_one) { FactoryBot.create(:child_object, oid: "12345", parent_object: parent_to_redirect) }
  let(:child_two) { FactoryBot.create(:child_object, oid: "67890", parent_object: parent_to_redirect) }

  describe "redirected parent" do
    before do
      stub_ptiffs_and_manifests
      login_as(:user)
      parent_to_receive_children
      parent_to_redirect
      child_one
      child_two
      user.add_role(:editor, admin_set)
      batch_process.user_id = user.id
      batch_process.file = redirect
    end

    it "does not create manifest or pdfs" do
      # both parents are indexed
      expect(SolrIndexJob).to receive(:perform_later).exactly(2).times
      # only the one non-redirected parent generates the manifest
      # rubocop:disable RSpec/AnyInstance
      expect_any_instance_of(GenerateManifestJob).to receive(:generate_manifest).exactly(1).times
      # rubocop:enable RSpec/AnyInstance
      # only the one non-redirected parent generates the pdf
      expect(GeneratePdfJob).to receive(:perform_later).exactly(1).times

      # run the reassociate batch
      batch_process.save
      po_old_three = ParentObject.find(2_004_551)
      # created redirect
      expect(po_old_three.redirect_to).to eq("https://collections.library.yale.edu/catalog/2004550")
      expect(po_old_three.visibility).to eq("Redirect")
    end
  end
end

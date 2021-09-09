# frozen_string_literal: true
require "rails_helper"

RSpec.describe "rake child_objects save_child_oids_to_csv", type: :task, prep_metadata_sources: true, prep_admin_sets: true, clean: true do
  let(:admin_set) { FactoryBot.create(:admin_set, key: 'brbl', label: 'brbl') }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2005512", admin_set_id: admin_set.id) }

  before do
    stub_metadata_cloud("2005512")
    stub_ptiffs_and_manifests
    parent_object
  end

  after do
    File.delete("data/child_oids.csv") if File.exist?("data/child_oids.csv")
  end

  around do |example|
    perform_enqueued_jobs do
      original_path_ocr = ENV['OCR_DOWNLOAD_BUCKET']
      ENV['OCR_DOWNLOAD_BUCKET'] = "yul-dc-ocr-test"
      example.run
      ENV['OCR_DOWNLOAD_BUCKET'] = original_path_ocr
    end
  end

  pending context 'with parent object with child objects' do
    it 'creates a csv with child objects' do
      Rake::Task["child_objects:save_child_oids_to_csv"].invoke
      file = File.read(Rails.root.join("data", "child_oids.csv"))
      CSV.parse(file, headers: true) do |row|
        oids = []
        oid = row[0]
        oids << oid
      end
      expect(oids[0]).to eq "2034600"
      expect(oids[1]).to eq "2046567"
      expect(File.exist?("data/child_oids.csv")).to be true
    end
  end
end

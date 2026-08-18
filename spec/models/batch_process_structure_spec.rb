# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcess, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  subject(:batch_process) { described_class.new(batch_action: "update structure ranges", user_id: user.id) }

  let(:user) { FactoryBot.create(:user, uid: "mk2525") }
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2002826", admin_set_id: admin_set.id) }
  let(:parent_object_two) { FactoryBot.create(:parent_object, oid: "2004548", admin_set_id: admin_set.id) }
  let(:child_one) { FactoryBot.create(:child_object, oid: "9011398", order: 1, label: "one", parent_object: parent_object) }
  let(:child_two) { FactoryBot.create(:child_object, oid: "9021925", order: 2, label: "two", parent_object: parent_object) }
  let(:child_three) { FactoryBot.create(:child_object, oid: "9021926", order: 3, label: "three", parent_object: parent_object) }
  let(:child_four) { FactoryBot.create(:child_object, oid: "9030368", order: 4, label: "four", parent_object: parent_object) }
  let(:other_child) { FactoryBot.create(:child_object, oid: "9111398", order: 1, label: "a", parent_object: parent_object_two) }
  let(:other_child_two) { FactoryBot.create(:child_object, oid: "9111399", order: 2, label: "b", parent_object: parent_object_two) }

  def upload(fixture)
    batch_process.file = Rack::Test::UploadedFile.new(Rails.root.join(fixture_paths[0], "csv", fixture))
    batch_process.save
  end

  def ranges_for(oid)
    StructureRange.where(parent_object_oid: oid).order(:position)
  end

  def canvas_oids_for(range)
    range.structures.where(type: 'StructureCanvas').order(:position).pluck(:child_object_oid)
  end

  around do |example|
    perform_enqueued_jobs { example.run }
  end

  before do
    stub_metadata_cloud("2002826")
    stub_metadata_cloud("2004548")
    stub_ptiffs_and_manifests
    parent_object
    child_one
    child_two
    child_three
    child_four
    login_as(:user)
    user.add_role(:editor, admin_set)
  end

  describe "applying structure from a csv" do
    before { upload("structure_ranges_example.csv") }

    it "creates a top level range per range_name, ordered by range_order" do
      expect(ranges_for(2_002_826).pluck(:label)).to eq ["Folder 1", "Folder 2"]
      expect(ranges_for(2_002_826).pluck(:position)).to eq [0, 1]
      expect(ranges_for(2_002_826).pluck(:top_level)).to eq [true, true]
      expect(ranges_for(2_002_826).pluck(:structure_id)).to eq [nil, nil]
    end

    it "files each child into its range, ordered by order_in_range" do
      folder_one, folder_two = ranges_for(2_002_826).to_a
      expect(canvas_oids_for(folder_one)).to eq [9_011_398, 9_021_925]
      expect(canvas_oids_for(folder_two)).to eq [9_030_368, 9_021_926]
    end

    it "marks every row it creates as editor built" do
      expect(Structure.where(parent_object_oid: 2_002_826).pluck(:source).uniq).to eq [Structure::EDITOR]
    end

    it "builds canvas resource ids the same way the structure editor does" do
      canvas = StructureCanvas.find_by(parent_object_oid: 2_002_826, child_object_oid: 9_011_398)
      expect(canvas.resource_id).to eq IiifRangeBuilder.child_id_to_uri(9_011_398, 2_002_826)
    end

    it "does not change the order of the child objects" do
      expect(ChildObject.find(9_011_398).order).to eq 1
      expect(ChildObject.find(9_021_925).order).to eq 2
      expect(ChildObject.find(9_021_926).order).to eq 3
      expect(ChildObject.find(9_030_368).order).to eq 4
    end

    it "emits the structure into the iiif manifest" do
      structures = ParentObject.find(2_002_826).iiif_presentation.manifest["structures"]
      expect(structures.map { |s| s["label"]["en"].first }).to eq ["Folder 1", "Folder 2"]
      expect(structures.first["items"].map { |i| i["id"] }).to eq [
        IiifRangeBuilder.child_id_to_uri(9_011_398, 2_002_826),
        IiifRangeBuilder.child_id_to_uri(9_021_925, 2_002_826)
      ]
    end

    it "reports the parent as complete" do
      expect(batch_process.batch_status).to eq "Batch complete"
    end
  end

  describe "with more than one parent in the csv" do
    before do
      parent_object_two
      other_child
      other_child_two
      upload("structure_ranges_multi_parent.csv")
    end

    it "applies structure to each parent" do
      expect(ranges_for(2_002_826).pluck(:label)).to eq ["Folder 1"]
      expect(ranges_for(2_004_548).pluck(:label)).to eq ["Section A"]
      expect(canvas_oids_for(ranges_for(2_004_548).first)).to eq [9_111_398, 9_111_399]
    end
  end

  describe "replacing existing structure" do
    let(:stale_range) do
      StructureRange.create!(resource_id: SecureRandom.uuid, label: "Stale", position: 0, top_level: true,
                             parent_object_oid: 2_002_826, source: Structure::EDITOR)
    end
    let(:preservica_range) do
      StructureRange.create!(resource_id: "b8b8-preservica", label: "Preservica Folder", position: 0, top_level: true,
                             parent_object_oid: 2_002_826, source: Structure::PRESERVICA)
    end

    it "removes editor built structure that is not in the csv" do
      stale_range
      StructureCanvas.create!(resource_id: IiifRangeBuilder.child_id_to_uri(9_011_398, 2_002_826), position: 0,
                              parent_object_oid: 2_002_826, child_object_oid: 9_011_398,
                              structure_id: stale_range.id, source: Structure::EDITOR)
      upload("structure_ranges_example.csv")

      expect(StructureRange.where(id: stale_range.id)).to be_empty
      expect(ranges_for(2_002_826).pluck(:label)).to eq ["Folder 1", "Folder 2"]
    end

    it "leaves preservica built structure alone" do
      preservica_canvas = StructureCanvas.create!(resource_id: IiifRangeBuilder.child_id_to_uri(9_021_926, 2_002_826),
                                                  position: 0, parent_object_oid: 2_002_826,
                                                  child_object_oid: 9_021_926, structure_id: preservica_range.id,
                                                  source: Structure::PRESERVICA)
      upload("structure_ranges_example.csv")

      expect(preservica_range.reload.label).to eq "Preservica Folder"
      expect(preservica_canvas.reload.structure_id).to eq preservica_range.id
    end

    it "returns a preservica range nested in a removed editor range to the top level" do
      preservica_range.update!(structure_id: stale_range.id, top_level: false)
      upload("structure_ranges_example.csv")

      expect(preservica_range.reload.structure_id).to be_nil
    end

    it "produces the same structure when the same csv is uploaded twice" do
      upload("structure_ranges_example.csv")
      first_resource_ids = ranges_for(2_002_826).pluck(:resource_id)

      second_process = described_class.new(batch_action: "update structure ranges", user_id: user.id)
      second_process.file = Rack::Test::UploadedFile.new(Rails.root.join(fixture_paths[0], "csv", "structure_ranges_example.csv"))
      second_process.save

      expect(ranges_for(2_002_826).pluck(:label)).to eq ["Folder 1", "Folder 2"]
      expect(canvas_oids_for(ranges_for(2_002_826).first)).to eq [9_011_398, 9_021_925]
      # range uuids are regenerated on every upload; nothing external references them
      expect(ranges_for(2_002_826).pluck(:resource_id)).not_to eq first_resource_ids
    end
  end

  describe "rows that cannot be applied" do
    let(:existing_range) do
      StructureRange.create!(resource_id: SecureRandom.uuid, label: "Untouched", position: 0,
                             top_level: true, parent_object_oid: 2_002_826, source: Structure::EDITOR)
    end

    it "leaves the parent untouched when a child is missing or belongs to another parent" do
      parent_object_two
      other_child
      existing_range
      upload("structure_ranges_invalid_child.csv")

      expect(ranges_for(2_002_826).pluck(:label)).to eq ["Untouched"]
      expect(batch_process.batch_ingest_events.pluck(:reason)).to include(
        "Skipping row [3] with parent oid: 2002826 because child oid: 999999999 was not found in local database",
        "Skipping row [4] with parent oid: 2002826 because child oid: 9111398 belongs to parent object: 2004548",
        "Skipping parent oid: 2002826 because one or more of its rows were invalid. No structure was changed for this parent."
      )
      expect(batch_process.batch_ingest_events.pluck(:status)).to include('Skipped Row')
    end

    it "reports every invalid row rather than stopping at the first" do
      existing_range
      upload("structure_ranges_invalid_order.csv")

      expect(ranges_for(2_002_826).pluck(:label)).to eq ["Untouched"]
      expect(batch_process.batch_ingest_events.pluck(:reason)).to include(
        "Skipping row [2] with parent oid: 2002826 because order_in_range [one] is not a non-negative integer",
        "Skipping row [3] with parent oid: 2002826 because range_order [first] is not a non-negative integer"
      )
    end

    it "leaves the parent untouched when a row contradicts the range_order set by an earlier row" do
      existing_range
      upload("structure_ranges_conflicting_range_order.csv")

      expect(ranges_for(2_002_826).pluck(:label)).to eq ["Untouched"]
      expect(batch_process.batch_ingest_events.pluck(:reason)).to include(
        "Skipping row [3] with parent oid: 2002826 because range [Folder 1] has conflicting range_order values [1] and [3]"
      )
    end

    it "leaves the parent untouched when a child is listed twice in the same range" do
      existing_range
      upload("structure_ranges_duplicate_child.csv")

      expect(ranges_for(2_002_826).pluck(:label)).to eq ["Untouched"]
      expect(batch_process.batch_ingest_events.pluck(:reason)).to include(
        "Skipping row [3] with parent oid: 2002826 because child oid: 9011398 appears more than once in range [Folder 1]"
      )
    end

    it "leaves the parent untouched when a required value is blank" do
      existing_range
      upload("structure_ranges_blank_values.csv")

      expect(ranges_for(2_002_826).pluck(:label)).to eq ["Untouched"]
      expect(batch_process.batch_ingest_events.pluck(:reason)).to include(
        "Skipping row [2] with parent oid: 2002826 because child_oid is blank",
        "Skipping row [3] with parent oid: 2002826 because range_name is blank"
      )
      expect(batch_process.batch_ingest_events.pluck(:status)).to include('Invalid Blank')
    end

    it "marks the rejected parent as failed" do
      upload("structure_ranges_duplicate_child.csv")

      expect(batch_process.batch_status).to eq "Batch failed"
      connection = batch_process.batch_connections.find_by(connectable: ParentObject.find(2_002_826))
      expect(IngestEvent.where(batch_connection: connection).pluck(:reason)).to include(
        "Structure was not applied because one or more CSV rows were invalid"
      )
    end

    it "still applies the parents whose rows were all valid" do
      parent_object_two
      other_child
      other_child_two
      existing_range
      upload("structure_ranges_one_bad_parent.csv")

      expect(ranges_for(2_002_826).pluck(:label)).to eq ["Untouched"]
      expect(ranges_for(2_004_548).pluck(:label)).to eq ["Section A"]
      expect(canvas_oids_for(ranges_for(2_004_548).first)).to eq [9_111_398, 9_111_399]
    end

    it "aborts the run when a row has a blank oid, since no parent can be shown to be complete" do
      existing_range
      upload("structure_ranges_blank_oid.csv")

      expect(ranges_for(2_002_826).pluck(:label)).to eq ["Untouched"]
      expect(batch_process.batch_ingest_events.pluck(:reason)).to include(
        "Process failed. Row [3] has a blank oid."
      )
      expect(batch_process.batch_ingest_events.pluck(:status)).to include('error')
    end

    it "aborts the run when a required column is missing" do
      upload("structure_ranges_missing_column.csv")

      expect(Structure.where(parent_object_oid: 2_002_826)).to be_empty
      expect(batch_process.batch_ingest_events.pluck(:reason)).to include(
        "Process failed. The CSV is missing required column(s): range_order"
      )
      expect(batch_process.batch_ingest_events.pluck(:status)).to include('error')
    end
  end

  describe "as a user without an editor role" do
    let(:user) { FactoryBot.create(:user, uid: "vw2525") }

    before do
      user.remove_role(:editor, admin_set)
      user.add_role(:viewer, admin_set)
      upload("structure_ranges_example.csv")
    end

    it "does not create any structure" do
      expect(Structure.where(parent_object_oid: 2_002_826)).to be_empty
      expect(batch_process.batch_ingest_events.pluck(:status)).to include('Permission Denied')
    end
  end

  describe "manifest regeneration" do
    it "queues one manifest job for the parent, not one per row" do
      expect(GenerateManifestJob).to receive(:perform_later).once.and_call_original
      upload("structure_ranges_example.csv")
    end

    it "reindexes rather than regenerating when the parent is redirected" do
      parent_object.update!(redirect_to: "https://collections.library.yale.edu/catalog/2004548")
      expect(GenerateManifestJob).not_to receive(:perform_later)
      upload("structure_ranges_example.csv")

      expect(ranges_for(2_002_826).pluck(:label)).to eq ["Folder 1", "Folder 2"]
    end
  end
end

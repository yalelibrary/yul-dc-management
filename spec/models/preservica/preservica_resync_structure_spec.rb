# frozen_string_literal: true

require 'rails_helper'

# Unit coverage for ParentObject#preservica_rebuild_structure, the full teardown/rebuild of the
# IIIF structure (ranges/canvases) that runs at the end of a Preservica resync. Driving the method
# directly keeps the three scenarios deterministic without needing per-scenario Preservica response
# fixtures; the end-to-end batch resync path is covered in preservica_sync_spec.rb.
RSpec.describe ParentObject, type: :model, prep_metadata_sources: true, prep_admin_sets: true do
  let(:parent) { FactoryBot.create(:parent_object, oid: 200_000_000) }

  # Every scenario here is a genuine folder (one information object grouping multiple images), so
  # the folder-architecture flag PreservicaImageService sets during a resync is true.
  before { parent.preservica_folder_architecture = true }

  # A folder maps to a Preservica information object (a StructureRange); the content object index is
  # the canvas position within that folder.
  let(:folder_a) { 'aaaa0001-0000-4000-8000-000000000001' }

  # rubocop:disable Metrics/ParameterLists
  def add_child(oid:, content_index:, order:, folder_id: folder_a, folder_index: 0, folder_label: 'Folder A')
    FactoryBot.create(:child_object,
                      parent_object: parent,
                      oid: oid,
                      caption: "image_#{oid}.tif",
                      order: order,
                      preservica_information_object_id: folder_id,
                      preservica_folder_label: folder_label,
                      preservica_folder_index: folder_index,
                      preservica_content_object_index: content_index)
  end
  # rubocop:enable Metrics/ParameterLists

  # The structures array as it would be emitted into the manifest, without needing full
  # canvas/image generation (add_structures_to_manifest reads only Structure records).
  def manifest_structures
    parent.reload
    structures = []
    IiifPresentationV3.new(parent).add_structures_to_manifest(structures)
    structures
  end

  # Canvas ids for each range, in order, under the top-level wrapper.
  def range_canvas_ids
    (manifest_structures.first&.fetch('items', []) || []).map do |range|
      (range['items'] || []).map { |canvas| canvas['id'] }
    end
  end

  def canvas_uri(oid)
    IiifRangeBuilder.child_id_to_uri(oid, parent.oid)
  end

  context 'when a child object has been added in Preservica' do
    it 'includes the new canvas in its range after rebuild' do
      add_child(oid: 200_000_001, content_index: 0, order: 1)
      add_child(oid: 200_000_002, content_index: 1, order: 2)
      parent.preservica_rebuild_structure
      expect(range_canvas_ids).to eq [[canvas_uri(200_000_001), canvas_uri(200_000_002)]]

      # a new content object appears in the same folder
      add_child(oid: 200_000_003, content_index: 2, order: 3)
      parent.preservica_rebuild_structure

      expect(range_canvas_ids).to eq [[canvas_uri(200_000_001), canvas_uri(200_000_002), canvas_uri(200_000_003)]]
      expect(StructureCanvas.where(parent_object_oid: parent.oid).count).to eq 3
    end
  end

  context 'when a child object has been removed in Preservica' do
    it 'drops the canvas and clears the orphaned structure record after rebuild' do
      add_child(oid: 200_000_001, content_index: 0, order: 1)
      removed = add_child(oid: 200_000_002, content_index: 1, order: 2)
      add_child(oid: 200_000_003, content_index: 2, order: 3)
      parent.preservica_rebuild_structure
      expect(StructureCanvas.where(parent_object_oid: parent.oid).count).to eq 3

      # the child is destroyed during the resync (mirrors sync_from_preservica removing it),
      # which would leave an orphaned StructureCanvas without the rebuild
      removed.destroy!
      parent.preservica_rebuild_structure

      expect(range_canvas_ids).to eq [[canvas_uri(200_000_001), canvas_uri(200_000_003)]]
      expect(StructureCanvas.where(parent_object_oid: parent.oid).count).to eq 2
      expect(StructureCanvas.where(child_object_oid: 200_000_002)).to be_empty
    end
  end

  context 'when child objects have been reordered in Preservica' do
    it 'reflects the new order within the range after rebuild' do
      first = add_child(oid: 200_000_001, content_index: 0, order: 1)
      second = add_child(oid: 200_000_002, content_index: 1, order: 2)
      parent.preservica_rebuild_structure
      expect(range_canvas_ids).to eq [[canvas_uri(200_000_001), canvas_uri(200_000_002)]]

      # Preservica now returns the two content objects in the opposite order within the folder
      first.update!(preservica_content_object_index: 1)
      second.update!(preservica_content_object_index: 0)
      parent.preservica_rebuild_structure

      expect(range_canvas_ids).to eq [[canvas_uri(200_000_002), canvas_uri(200_000_001)]]
    end
  end
end

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

  # Canvas ids for each top-level folder range, in order (structures are the folder ranges directly).
  def range_canvas_ids
    manifest_structures.map do |range|
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

  # Preservica owns the ranges it generates and reasserts them on every resync; the editor owns
  # everything it built. Neither flow may clear the other's rows.
  context 'when a structure was hand built in the structure editor' do
    let(:hand_built) do
      StructureRange.create!(resource_id: SecureRandom.uuid, label: 'Hand Built Section', position: 5,
                             parent_object_oid: parent.oid, top_level: true, source: Structure::EDITOR)
    end

    def editor_save(structures)
      builder = IiifRangeBuilder.new
      manifest = { 'type' => 'Manifest', 'id' => "#{IiifRangeBuilder.manifest_base_url}/#{parent.oid}",
                   'structures' => structures }
      builder.prune_structures_for_editor_save(parent.oid, manifest)
      builder.parse_structures(manifest) if structures.any?
    end

    def range_json(structure, items = [])
      { 'type' => 'Range', 'id' => structure.resource_id,
        'label' => { 'en' => [structure.label] }, 'items' => items }
    end

    def canvas_json(oid)
      { 'type' => 'Canvas', 'id' => canvas_uri(oid) }
    end

    # An editor save destroys and recreates its own rows, so the hand built range comes back with a
    # new primary key. Identity across a save is the resource_id, not the id.
    def saved_hand_built
      StructureRange.editor_built.find_by(parent_object_oid: parent.oid, resource_id: hand_built.resource_id)
    end

    def two_children
      add_child(oid: 200_000_001, content_index: 0, order: 1)
      add_child(oid: 200_000_002, content_index: 1, order: 2)
    end

    def preservica_range
      StructureRange.preservica_built.find_by(parent_object_oid: parent.oid)
    end

    it 'survives a Preservica rebuild' do
      two_children
      hand_built
      parent.preservica_rebuild_structure

      expect(Structure.exists?(hand_built.id)).to be true
      expect(manifest_structures.map { |r| r['label']&.[]('en')&.first }).to include('Hand Built Section')
    end

    it 'keeps its own canvases when the same child is also in a Preservica range' do
      two_children
      parent.preservica_rebuild_structure

      editor_save([range_json(hand_built, [canvas_json(200_000_001)]),
                   range_json(preservica_range, [canvas_json(200_000_001), canvas_json(200_000_002)])])

      expect(StructureCanvas.where(parent_object_oid: parent.oid, child_object_oid: 200_000_001).count).to eq 2
      expect(StructureCanvas.editor_built.where(child_object_oid: 200_000_001).count).to eq 1
      expect(StructureCanvas.preservica_built.where(child_object_oid: 200_000_001).count).to eq 1
    end

    it 'does not clear Preservica rows on save, and keeps a Preservica range the editor nested' do
      two_children
      parent.preservica_rebuild_structure
      nested_json = range_json(preservica_range, [canvas_json(200_000_001), canvas_json(200_000_002)])

      # the editor files the Preservica range underneath the hand built one
      editor_save([range_json(hand_built, [nested_json])])

      expect(preservica_range.structure_id).to eq saved_hand_built.id
      expect(preservica_range.structures.count).to eq 2

      # a later resync regenerates the range but leaves it where the editor filed it
      parent.preservica_rebuild_structure

      expect(preservica_range.structure_id).to eq saved_hand_built.id
      expect(preservica_range.structures.count).to eq 2
      expect(saved_hand_built).to be_present
    end

    it 'lets the editor delete a Preservica range, and resync brings it back' do
      two_children
      parent.preservica_rebuild_structure

      editor_save([range_json(hand_built)])
      expect(StructureRange.preservica_built.where(parent_object_oid: parent.oid)).to be_empty
      expect(saved_hand_built).to be_present

      parent.preservica_rebuild_structure

      expect(StructureRange.preservica_built.where(parent_object_oid: parent.oid).count).to eq 1
      expect(saved_hand_built).to be_present
    end
  end
end

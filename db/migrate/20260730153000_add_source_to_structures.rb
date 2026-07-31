# frozen_string_literal: true

class AddSourceToStructures < ActiveRecord::Migration[7.2]
  def up
    add_column :structures, :source, :string, default: 'editor', null: false
    backfill_source
    replace_resource_id_index
  end

  def backfill_source
    execute <<~SQL.squish
      UPDATE structures s SET source = 'preservica'
      WHERE s.type = 'StructureRange'
        AND (EXISTS (SELECT 1 FROM child_objects c
                      WHERE c.parent_object_oid = s.parent_object_oid
                        AND c.preservica_information_object_id = s.resource_id)
             OR s.resource_id LIKE '%/manifests/' || s.parent_object_oid::text)
    SQL

    execute <<~SQL.squish
      UPDATE structures SET source = 'preservica'
      WHERE type = 'StructureCanvas'
        AND structure_id IN (SELECT id FROM structures WHERE source = 'preservica')
    SQL
  end

  # A canvas may now be referenced by both a Preservica folder range and a hand built range, so
  # resource_id can no longer be unique on its own. Duplicate ranges are still barred, and a canvas
  # still cannot appear twice inside the same range.
  def replace_resource_id_index
    remove_index :structures, name: 'index_structures_on_resource_id'
    add_index :structures, [:parent_object_oid, :resource_id],
              unique: true, where: "type = 'StructureRange'",
              name: 'index_structure_ranges_on_parent_and_resource_id'
    add_index :structures, [:structure_id, :resource_id],
              unique: true, where: "type = 'StructureCanvas'",
              name: 'index_structure_canvases_on_range_and_resource_id'
    add_index :structures, [:parent_object_oid, :source]
  end

  def down
    remove_index :structures, [:parent_object_oid, :source]
    remove_index :structures, name: 'index_structure_canvases_on_range_and_resource_id'
    remove_index :structures, name: 'index_structure_ranges_on_parent_and_resource_id'
    add_index :structures, :resource_id, unique: true
    remove_column :structures, :source
  end
end

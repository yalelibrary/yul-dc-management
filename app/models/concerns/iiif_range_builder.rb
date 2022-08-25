# frozen_string_literal: true

class IiifRangeBuilder
  PREFIX = 'https://collections.library.yale.edu/manifests'

  def parse_structures(manifest)
    raise 'Not a Manifest' unless manifest['type'] == 'Manifest'
    raise 'No structures property' unless manifest['structures'] && !manifest['structures'].empty?

    results = []
    manifest_uri = manifest['id']
    parent = parent_object_from_uri(manifest_uri)
    ActiveRecord::Base.transaction do
      structures = manifest['structures']
      structures.each_with_index do |structure, index|
        top_level_range = parse_range(parent, structure, index)
        top_level_range.top_level = true
        top_level_range.save
        results.push top_level_range
      end
    end
    results
  end

  # rubocop:disable Metrics/MethodLength
  def parse_range(parent, range, position)
    raise 'Not a Range' unless range['type'] == 'Range'

    uri = range['id']
    id = uuid_from_uri(uri)
    destroy_existing_structure(id)
    result = StructureRange.create!(
      resource_id: id,
      label: range&.[]('label')&.[]('en')&.[](0) || range['label'].to_s,
      position: position,
      parent_object_oid: parent.oid
    )
    items = range['items']

    items.each_with_index do |item, index|
      if item['type'] == 'Range'
        result.structures << parse_range(parent, item, index)
      elsif item['type'] == 'Canvas'
        result.structures << parse_canvas(parent, item, index)
      else
        raise 'Unexpected type for item in Range'
      end
    end
    result.save
    result
  end
  # rubocop:enable Metrics/MethodLength

  def parse_canvas(parent, item, position)
    child_id = child_id_from_uri(item['id'], parent.id)
    child = ChildObject.find(child_id)
    StructureCanvas.create!(
      resource_id: item['id'],
      label: child.label,
      position: position,
      parent_object_oid: parent.oid,
      child_object_oid: child.oid
    )
  end

  def uuid_from_uri(uri)
    uri.sub("#{PREFIX}/range/", '')
  end

  def parent_object_from_uri(uri)
    parent_oid = parent_oid_from_uri(uri)
    ParentObject.find(parent_oid)
  end

  def parent_oid_from_uri(uri)
    uri.sub(/.*manifests\//, '')
  end

  def self.parent_uri_from_id(id)
    "#{PREFIX}/#{id}"
  end

  def self.uuid_to_uri(uuid)
    "#{PREFIX}/range/#{uuid}"
  end

  def child_id_from_uri(uri, parent_oid)
    uri.sub(/.*oid\/#{parent_oid}\/canvas\//, '')
  end

  def self.child_id_to_uri(child_oid, parent_oid)
    "#{PREFIX}/oid/#{parent_oid}/canvas/#{child_oid}"
  end

  def destroy_existing_structure(resource_id)
    Structure.where(resource_id: resource_id).destroy_all
  end

  def destroy_existing_structure_by_parent_oid(parent_oid)
    Structure.where(parent_object_oid: parent_oid).destroy_all
  end
end

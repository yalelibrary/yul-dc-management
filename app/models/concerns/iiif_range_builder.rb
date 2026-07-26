# frozen_string_literal: true

class IiifRangeBuilder
  # Fallback when IIIF_MANIFESTS_BASE_URL is unset. Must stay in sync with the manifest itself --
  # IiifPresentationV3#manifest_base_url delegates here so the ids this class mints for ranges and
  # canvases always match the ids IiifPresentationV3 mints for the manifest and its canvases. When
  # they disagree, Universal Viewer cannot resolve a Range's items to the Canvases in the manifest
  # and the range renders but is not navigable.
  DEFAULT_BASE_URL = 'http://localhost/manifests'

  def self.manifest_base_url
    (ENV['IIIF_MANIFESTS_BASE_URL'].presence || DEFAULT_BASE_URL).sub(%r{/+\z}, '')
  end

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
        top_level_range.save!
        results.push top_level_range
      end
    end
    results
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
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
    result.save!
    result
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

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

  # Range ids arrive either as a bare uuid (what IiifPresentationV3 emits today) or as a
  # "<base>/range/<uuid>" uri (older manifests). Deliberately base-url agnostic so a manifest
  # generated under one IIIF_MANIFESTS_BASE_URL still parses under another.
  def uuid_from_uri(uri)
    uri.split('/').last
  end

  def parent_object_from_uri(uri)
    parent_oid = parent_oid_from_uri(uri)
    ParentObject.find(parent_oid)
  end

  # Manifest ids come as "<base>/<oid>" (what IiifPresentationV3 emits) or "<base>/oid/<oid>"
  # (older manifests). The oid is the last path segment in both.
  def parent_oid_from_uri(uri)
    uri.split('/').last
  end

  def self.parent_uri_from_id(id)
    File.join(manifest_base_url, id.to_s)
  end

  def self.uuid_to_uri(uuid)
    File.join(manifest_base_url, 'range', uuid.to_s)
  end

  def child_id_from_uri(uri, parent_oid)
    uri.sub(/.*oid\/#{parent_oid}\/canvas\//, '')
  end

  def self.child_id_to_uri(child_oid, parent_oid)
    File.join(manifest_base_url, "oid/#{parent_oid}/canvas/#{child_oid}")
  end

  def destroy_existing_structure(resource_id)
    Structure.where(resource_id: resource_id).destroy_all
  end

  def destroy_existing_structure_by_parent_oid(parent_oid)
    Structure.where(parent_object_oid: parent_oid).destroy_all
  end
end

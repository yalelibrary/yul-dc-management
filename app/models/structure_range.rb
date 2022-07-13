# frozen_string_literal: true

class StructureRange < Structure
  def parent_range
    return nil unless structure_id

    StructureRange.find(structure_id)
  end

  def child_structures_as_iiif
    children = []
    structures.order('position').each do |s|
      children << s.to_iiif
    end
    children
  end

  # rubocop:disable Metrics/MethodLength
  def to_iiif
    part_of = []
    if parent_range
      part_of << {
        id: IiifRangeBuilder.uuid_to_uri(parent_range.resource_id),
        type: 'Range'
      }
    elsif top_level
      part_of << {
        id: IiifRangeBuilder.parent_uri_from_id(parent_object_oid),
        type: 'Manifest'
      }
    end

    {
      id: IiifRangeBuilder.uuid_to_uri(resource_id),
      type: 'Range',
      label: { "en": [label] },
      items: child_structures_as_iiif,
      partOf: part_of
    }
  end
  # rubocop:enable Metrics/MethodLength
end

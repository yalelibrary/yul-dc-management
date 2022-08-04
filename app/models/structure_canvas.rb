# frozen_string_literal: true

class StructureCanvas < Structure
  belongs_to :child_object, foreign_key: 'child_object_oid'

  def to_iiif
    {
      id: IiifRangeBuilder.child_id_to_uri(child_object.oid, parent_object.oid),
      type: 'Canvas'
    }
  end
end

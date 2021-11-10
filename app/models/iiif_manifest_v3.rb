# frozen_string_literal: true

class IiifManifestV3 < Hash
  def items
    self['items']
  end
end

# frozen_string_literal: true

class StaticChildInfo
  SIZE_FILE_PATH = Rails.root.join('db', 'child_object_sizes.json')
  SIZES = JSON.parse(File.read(SIZE_FILE_PATH))

  def self.size_for(oid)
    SIZES[oid] || { width: 1486, height: 2051 } if Rails.env.development?
  end

  def self.write_sizes
    result = {}
    ChildObject.find_each do |child|
      result[child.oid] = { width: child.width, height: child.height } if child.width && child.height
    end
    File.write(FILE_PATH, JSON.pretty_generate(result))
  end
end

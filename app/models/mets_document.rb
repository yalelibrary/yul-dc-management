# frozen_string_literal: true

class MetsDocument
  include MetsStructure
  attr_reader :source_xml
  # Takes a path to the mets file
  def initialize(mets_xml)
    @source_xml = mets_xml
    @mets = Nokogiri::XML(@source_xml)
  end

  def oid
    @mets.xpath("//mods:recordIdentifier[@source='local']").inner_text
  end

  def uuid
    @mets.xpath("//mods:recordIdentifier[@source='gbv-ppn']").inner_text
  end

  def valid_mets?
    return false unless @mets.xml?
    return false unless @mets.collect_namespaces.include?("xmlns:mets")
    return false unless @mets.xpath("//mets:file").count >= 1
    true
  end

  def all_images_present?
    mount_path = ENV["ACCESS_MASTER_MOUNT"] || "brbl-dsu"
    files.all? { |file| File.exist?(Rails.root.join(mount_path, file[:url])) }
  end

  # def viewing_direction
  #   right_to_left ? "right-to-left" : "left-to-right"
  # end

  # def right_to_left
  #   @mets.xpath("/mets:mets/mets:structMap[@TYPE='logical']/mets:div/@TYPE") \
  #        .to_s.start_with? 'RTL'
  # end

  # Combines the physical info and file info for a given image, used for iiif manifest creation
  def combined
    zipped = files.zip(physical_divs)
    zipped.map { |file, physical_div| file.merge(physical_div) }
  end

  def physical_divs
    @mets.xpath("/mets:mets/mets:structMap[@TYPE='PHYSICAL']/mets:div" \
                "/mets:div").map do |p|
      physical_info(p)
    end
  end

  def physical_info(physical_div)
    {
      phys_id: physical_div.xpath('@ID').to_s,
      file_id: physical_div.xpath('mets:fptr/@FILEID').to_s,
      order_label: physical_div.xpath("@ORDERLABEL").to_s,
      order: physical_div.xpath("@ORDER").to_s
    }
  end

  def files
    @mets.xpath("/mets:mets/mets:fileSec/mets:fileGrp/mets:file").map do |f|
      file_info(f)
    end
  end

  def file_info(file)
    mount_path = ENV["ACCESS_MASTER_MOUNT"] || "brbl-dsu"
    {
      id: file.xpath('@ID').to_s,
      checksum: file.xpath('@CHECKSUM').to_s,
      mime_type: file.xpath('@MIMETYPE').to_s,
      url: file.xpath('mets:FLocat/@xlink:href').to_s.gsub(/file:\/\/\/#{mount_path}\//, ''),
      image_id: file.xpath('mets:FLocat/@xlink:href').to_s.match(/#{oid}\/media\/(\d*)/)[1]
    }
  end

  # def file_opts(file)
  #   return {} if
  #     @mets.xpath("count(//mets:div/mets:fptr[@FILEID='#{file[:id]}'])") \
  #          .to_i.positive?
  #   { viewing_hint: 'non-paged' }
  # end
end
